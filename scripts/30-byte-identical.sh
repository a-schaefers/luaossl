#!/bin/bash
# Claim C4: "built with -std=gnu17 from the same path, the object file is byte-for-byte identical
# before and after this commit (GCC 14.2 and Clang 18.1, OpenSSL 3.0.13)".
# Builds src/openssl.c with the rockspec's flags (config.h.diff applied, -O2 -fPIC, its -D flags),
# each revision extracted into the SAME directory, then compares the objects with cmp and sha256.
# Also: the thread's later claim that the #ifdef version (950e54e) is identical to 63f211b in gnu17 AND gnu23.
set -u
REPO=/home/claude/luaossl
W=/srv/verify/work/same
OBJ=/srv/verify/work/objs
rm -rf $W $OBJ; mkdir -p $W $OBJ
cp /srv/verify/work/matrix/config.h.diff /srv/verify/work/config.h.diff 2>/dev/null
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') byte-identical objects"
gcc-14 --version | head -1; clang-18 --version | head -1; echo "OpenSSL headers: $(grep -h 'define OPENSSL_VERSION_TEXT' /usr/include/openssl/opensslv.h)"
for rev in e5cd207 63f211b 950e54e; do
  rm -rf $W/luaossl; mkdir -p $W/luaossl
  git -C $REPO archive $rev | tar -x -C $W/luaossl
  (cd $W/luaossl && patch -s -p1 < /srv/verify/work/config.h.diff)
  for cc in gcc-14 clang-18; do for std in gnu17 gnu23; do
    cmd="$cc -O2 -fPIC -std=$std -I/usr/include/lua5.4 -D_REENTRANT -D_THREAD_SAFE -DCOMPAT53_PREFIX=luaossl -D_GNU_SOURCE -c src/openssl.c -o openssl.o"
    (cd $W/luaossl && rm -f openssl.o && $cmd > /dev/null 2>&1); rc=$?
    if [ $rc = 0 ]; then cp $W/luaossl/openssl.o $OBJ/$rev-$cc-$std.o; s="sha256 $(sha256sum $OBJ/$rev-$cc-$std.o | cut -c1-64)  size $(stat -c %s $OBJ/$rev-$cc-$std.o)"; else s="compile FAILED (exit $rc)"; fi
    printf '%s %-8s %-6s cwd=%s : %s\n' $rev $cc $std "$W/luaossl" "$s"
  done; done
done
echo "command: <cc> -O2 -fPIC -std=<std> -I/usr/include/lua5.4 -D_REENTRANT -D_THREAD_SAFE -DCOMPAT53_PREFIX=luaossl -D_GNU_SOURCE -c src/openssl.c -o openssl.o"
echo
echo "--- comparisons (cmp exit 0 = byte-for-byte identical)"
cmpit() { if [ -f $OBJ/$1.o ] && [ -f $OBJ/$2.o ]; then cmp $OBJ/$1.o $OBJ/$2.o > /tmp/cmp.$$ 2>&1; r=$?; printf '%-24s vs %-24s cmp exit %s %s\n' $1 $2 $r "$( [ $r = 0 ] && echo IDENTICAL || cat /tmp/cmp.$$)"; else printf '%-24s vs %-24s n/a (one side did not compile)\n' $1 $2; fi; }
for cc in gcc-14 clang-18; do
  cmpit e5cd207-$cc-gnu17 63f211b-$cc-gnu17
  cmpit e5cd207-$cc-gnu17 950e54e-$cc-gnu17
  cmpit 63f211b-$cc-gnu17 950e54e-$cc-gnu17
  cmpit 63f211b-$cc-gnu23 950e54e-$cc-gnu23
  cmpit 950e54e-$cc-gnu17 950e54e-$cc-gnu23
done
rm -f /tmp/cmp.$$
echo
echo "--- for reference: or_toPEM in the 950e54e gcc-14 gnu17 object calls PEM_ASN1_write_bio (the #ifdef branch)"
objdump -d --no-show-raw-insn --disassemble=or_toPEM -r $OBJ/950e54e-gcc-14-gnu17.o | grep -E 'or_toPEM>:|R_X86_64_PLT32|R_X86_64_PC32|call' | head -20
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') byte-identical objects"
