#!/bin/bash
# Claim C3: GCC 14.2 and Clang 18.1, -std=gnu17 and -std=gnu23, against OpenSSL 1.1.1w, 3.0.13
# and 4.0.3 headers. Compiles src/openssl.c exactly like the rockspec does (its config.h.diff
# patch applied, same -D/-I flags, -O2 -fPIC) plus -Wall -Wextra. Compile only (-c): the 1.1.1w
# and 4.0.3 trees are headers only, so nothing is linked here.
# Revisions: e5cd207 (before), 63f211b (first version of the fix), 950e54e (PR #222 head).
set -u
REPO=/home/claude/luaossl
W=/srv/verify/work/matrix
OUT=/srv/verify/logs/20-header-matrix
rm -rf $W $OUT; mkdir -p $W $OUT
declare -A INC=([1.1.1w]="-I/srv/verify/src/openssl-1.1.1w/include" [3.0.13]="" [4.0.3]="-I/srv/verify/src/openssl-4.0.3/include")
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') header matrix"
gcc-14 --version | head -1; clang-18 --version | head -1
for o in 1.1.1w 3.0.13 4.0.3; do
  printf '%-7s headers -> %s\n' $o "$(printf '#include <openssl/opensslv.h>\nOPENSSL_VERSION_TEXT\n' | gcc-14 -E -P ${INC[$o]} -x c - | tail -1)"
done
# the rockspec's own patch (build.patches["config.h.diff"])
cat > $W/config.h.diff <<'PATCH'
--- a/src/openssl.c
+++ b/src/openssl.c
@@ -26,3 +26 @@
-#if HAVE_CONFIG_H
-#include "config.h"
-#endif
+#include "../config.h.guess"
PATCH
printf '%-8s %-9s %-6s %-7s %-6s %-6s %-8s %s\n' rev cc std openssl exit errors warnings first-error
for rev in e5cd207 63f211b 950e54e; do
  rm -rf $W/src; mkdir -p $W/src
  git -C $REPO archive $rev | tar -x -C $W/src
  (cd $W/src && patch -s -p1 < $W/config.h.diff) || echo "PATCH FAILED for $rev"
  for cc in gcc-14 clang-18; do for std in gnu17 gnu23; do for o in 1.1.1w 3.0.13 4.0.3; do
    log=$OUT/$rev-$cc-$std-$o.txt
    cmd="$cc -O2 -fPIC -std=$std -Wall -Wextra -I/usr/include/lua5.4 ${INC[$o]} -D_REENTRANT -D_THREAD_SAFE -DCOMPAT53_PREFIX=luaossl -D_GNU_SOURCE -c src/openssl.c -o openssl.o"
    { echo "# $(date -u '+%Y-%m-%dT%H:%M:%SZ') cwd=$W/src rev=$(git -C $REPO rev-parse $rev)"; echo "# $cmd"; } > $log
    (cd $W/src && $cmd) >> $log 2>&1; rc=$?
    echo "# exit status: $rc" >> $log
    e=$(grep -c ': error: ' $log); w=$(grep -c ': warning: ' $log)
    first=$(grep -m1 ': error: ' $log | sed -E 's/^src\/openssl\.c:([0-9]+:[0-9]+): error: /\1 /' | cut -c1-90)
    printf '%-8s %-9s %-6s %-7s %-6s %-6s %-8s %s\n' $rev $cc $std $o $rc $e $w "$first"
  done; done; done
done
echo
echo "--- warnings, before (e5cd207) vs after, line numbers stripped (error lines excluded)"
norm() { grep ': warning: ' "$1" | sed -E 's/^([^:]+):[0-9]+:[0-9]+:/\1:/' | sort | uniq -c; }
for after in 63f211b 950e54e; do
  for cc in gcc-14 clang-18; do for std in gnu17 gnu23; do for o in 1.1.1w 3.0.13 4.0.3; do
    a=$OUT/e5cd207-$cc-$std-$o.txt; b=$OUT/$after-$cc-$std-$o.txt
    if diff <(norm $a) <(norm $b) > /dev/null; then res="SAME ($(grep -c ': warning: ' $b) warnings)"; else res="DIFFERENT:"; fi
    printf 'e5cd207 vs %s %-9s %-6s %-7s %s\n' $after $cc $std $o "$res"
    [ "$res" = "DIFFERENT:" ] && diff <(norm $a) <(norm $b) | sed 's/^/    /'
  done; done; done
done
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') header matrix"
