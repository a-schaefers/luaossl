#!/bin/bash
# Follow-up to 20-header-matrix.sh. Where the unpatched C23 build fails (1.1.1w and 3.0.13 headers), its
# warning list is not a usable "before": GCC adds a cast warning for the broken macro, and Clang skips its
# end-of-file unused-function check once it has seen an error. This compares each patched C23 build with the
# unpatched gnu17 build of the same compiler and headers (how the old session defined "as before").
# Reads the per-build logs written by 20-header-matrix.sh; compiles nothing.
D=/srv/verify/logs/20-header-matrix
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') warnings: patched gnu23 vs unpatched gnu17"
norm() { grep ': warning: ' "$1" | sed -E 's/^([^:]+):[0-9]+:[0-9]+:/\1:/' | sort | uniq -c; }
for after in 63f211b 950e54e; do for cc in gcc-14 clang-18; do for o in 1.1.1w 3.0.13 4.0.3; do
  a=$D/e5cd207-$cc-gnu17-$o.txt; b=$D/$after-$cc-gnu23-$o.txt
  if diff <(norm $a) <(norm $b) > /dev/null; then r="SAME ($(grep -c ': warning: ' $a) vs $(grep -c ': warning: ' $b) warnings)"; else r="DIFFERENT"; fi
  printf 'e5cd207 gnu17 vs %s gnu23  %-9s %-7s %s\n' $after $cc $o "$r"
  [ "$r" = DIFFERENT ] && diff <(norm $a) <(norm $b) | sed 's/^/    /'
done; done; done
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') warnings: patched gnu23 vs unpatched gnu17"
