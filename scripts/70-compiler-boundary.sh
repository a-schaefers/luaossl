#!/bin/bash
# Background claim in the commit message: "GCC 14+ and Clang 16+ treat that [incompatible pointer
# type] as an error". Compiles unpatched e5cd207 (rockspec flags) in C23 mode against the host's
# OpenSSL 3.0.13 headers with the compiler just below and at each boundary. -std=gnu2x is used
# because GCC 13 and Clang 15 don't accept the gnu23 spelling.
set -u
REPO=/home/claude/luaossl
W=/srv/verify/work/boundary
rm -rf $W; mkdir -p $W/luaossl
git -C $REPO archive e5cd207 | tar -x -C $W/luaossl
(cd $W/luaossl && patch -s -p1 < /srv/verify/work/config.h.diff)
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') compiler boundary (unpatched e5cd207, OpenSSL 3.0.13 headers, -std=gnu2x)"
for cc in gcc-13 gcc-14 clang-15 clang-16 clang-18; do
  v=$($cc --version | head -1)
  (cd $W/luaossl && $cc -O2 -fPIC -std=gnu2x -I/usr/include/lua5.4 -D_REENTRANT -D_THREAD_SAFE -DCOMPAT53_PREFIX=luaossl -D_GNU_SOURCE -c src/openssl.c -o openssl.o) > $W/$cc.txt 2>&1; rc=$?
  diag=$(grep -E 'openssl\.c:1245[0-9]:[0-9]+: (error|warning):' $W/$cc.txt | head -1 | sed -E 's/^src\/openssl\.c://' | cut -c1-150)
  printf '%-9s exit=%s  %-50s | or_toPEM diagnostic: %s\n' $cc $rc "$v" "${diag:-(none)}"
done
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') compiler boundary"
