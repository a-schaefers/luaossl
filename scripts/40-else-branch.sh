#!/bin/bash
# Claim C6: "With the macro #undef'd and PEM_write_bio_OCSP_RESPONSE() declared as a function, as a
# future release might do, the #else branch compiles with GCC 14.2 and Clang 18.1 in both modes,
# against OpenSSL 3.0.13 and 4.0.3 headers, and calls that function."
# Method: take 950e54e (rockspec patch applied), insert just above or_toPEM():
#     #undef PEM_write_bio_OCSP_RESPONSE
#     int PEM_write_bio_OCSP_RESPONSE(BIO *bp, const OCSP_RESPONSE *o);
# compile, then inspect the object: or_toPEM must call PEM_write_bio_OCSP_RESPONSE and not PEM_ASN1_write_bio.
# Control: the unmodified 950e54e object calls PEM_ASN1_write_bio and has no PEM_write_bio_OCSP_RESPONSE symbol.
set -u
REPO=/home/claude/luaossl
W=/srv/verify/work/else
rm -rf $W; mkdir -p $W
declare -A INC=([3.0.13]="" [4.0.3]="-I/srv/verify/src/openssl-4.0.3/include")
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') #else branch check"
gcc-14 --version | head -1; clang-18 --version | head -1
for variant in control mock; do
  rm -rf $W/luaossl; mkdir -p $W/luaossl
  git -C $REPO archive 950e54e | tar -x -C $W/luaossl
  (cd $W/luaossl && patch -s -p1 < /srv/verify/work/config.h.diff)
  if [ $variant = mock ]; then
    sed -i 's/^static int or_toPEM(lua_State \*L) {$/#undef PEM_write_bio_OCSP_RESPONSE\nint PEM_write_bio_OCSP_RESPONSE(BIO *bp, const OCSP_RESPONSE *o);\n\n&/' $W/luaossl/src/openssl.c
  fi
  echo; echo "######## variant: $variant   (src/openssl.c around or_toPEM:)"
  grep -n -B3 -A16 '^static int or_toPEM' $W/luaossl/src/openssl.c | sed -n '1,22p'
  for cc in gcc-14 clang-18; do for std in gnu17 gnu23; do for o in 3.0.13 4.0.3; do
    cmd="$cc -O2 -fPIC -std=$std -Wall -Wextra -I/usr/include/lua5.4 ${INC[$o]} -D_REENTRANT -D_THREAD_SAFE -DCOMPAT53_PREFIX=luaossl -D_GNU_SOURCE -c src/openssl.c -o openssl.o"
    (cd $W/luaossl && rm -f openssl.o && $cmd > $W/out.txt 2>&1); rc=$?
    errs=$(grep -c ': error: ' $W/out.txt)
    if [ $rc = 0 ]; then
      dis=$(objdump -d -r --disassemble=or_toPEM $W/luaossl/openssl.o)
      calls_fn=$(echo "$dis" | grep -c 'R_X86_64_PLT32.*PEM_write_bio_OCSP_RESPONSE')
      calls_asn1=$(echo "$dis" | grep -c 'R_X86_64_PLT32.*PEM_ASN1_write_bio')
      sym=$(nm $W/luaossl/openssl.o | grep -w 'PEM_write_bio_OCSP_RESPONSE' | sed 's/^ *//')
      printf '%-7s %-8s %-6s %-6s exit=%s errors=%s | or_toPEM calls PEM_write_bio_OCSP_RESPONSE: %s, PEM_ASN1_write_bio: %s | nm: %s\n' $variant $cc $std $o $rc $errs $calls_fn $calls_asn1 "${sym:-(no symbol)}"
    else
      printf '%-7s %-8s %-6s %-6s exit=%s errors=%s COMPILE FAILED\n' $variant $cc $std $o $rc $errs; grep ': error: ' $W/out.txt | head -3
    fi
  done; done; done
done
echo; echo "--- or_toPEM disassembly, mock variant, last build (clang-18 gnu23, OpenSSL 4.0.3 headers):"
objdump -d -r --no-show-raw-insn --disassemble=or_toPEM $W/luaossl/openssl.o | grep -E 'or_toPEM>:|R_X86_64_PLT32'
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') #else branch check"
