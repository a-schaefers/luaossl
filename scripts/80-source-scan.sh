#!/bin/bash
# Claim "OCSP_RESPONSE:toPEM() (or_toPEM) is the only place left in luaossl that hits this".
# (1) List every macro in the OpenSSL 3.0.13 and 1.1.1w headers whose definition contains an old-style
#     empty-parameter function-pointer cast, the pattern C23 breaks: (int (*)()), (char *(*)()), (void *(*)()).
# (2) Find which of those macro names luaossl's src/openssl.c uses, at e5cd207, 63f211b and 950e54e.
# The matrix in 20-header-matrix.sh is the empirical check (patched C23 builds have no errors); this is the textual one.
set -u
REPO=/home/claude/luaossl
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') source scan"
T=$(mktemp -d)
for inc in /usr/include/openssl /srv/verify/src/openssl-1.1.1w/include/openssl; do
  echo "--- macros with an old-style cast in $inc ($(grep -h 'define OPENSSL_VERSION_TEXT' $inc/opensslv.h | sed 's/.*TEXT *//'))"
  # join continuation lines, then keep #define lines whose body has the cast
  for h in $inc/*.h; do sed -e ':a' -e '/\\$/N; s/\\\n/ /; ta' "$h"; done \
    | grep -E '^[[:space:]]*#[[:space:]]*define[[:space:]]+[A-Za-z0-9_]+\(' \
    | grep -E '\((int|char \*|void \*) ?\(\*\)\(\)\)' \
    | sed -E 's/^[[:space:]]*#[[:space:]]*define[[:space:]]+([A-Za-z0-9_]+)\(.*/\1/' | sort -u > $T/macros-$(basename $(dirname $(dirname $inc)))
  echo "$(wc -l < $T/macros-$(basename $(dirname $(dirname $inc)))) macros: $(tr '\n' ' ' < $T/macros-$(basename $(dirname $(dirname $inc))))"
done
sort -u $T/macros-* > $T/all
for rev in e5cd207 63f211b 950e54e; do
  echo; echo "--- uses in luaossl src/openssl.c at $rev ($(git -C $REPO rev-parse $rev))"
  git -C $REPO show $rev:src/openssl.c > $T/openssl.c
  n=0
  while read m; do
    hits=$(grep -n -w "$m" $T/openssl.c)
    [ -n "$hits" ] && { echo "$m:"; echo "$hits" | sed 's/^/    /'; n=$((n+1)); }
  done < $T/all
  echo "macros used: $n"
  echo "old-style casts in luaossl's own code, comment lines excluded: $(grep -E '\((int|char \*|void \*) ?\(\*\)\(\)\)' $T/openssl.c | grep -c -v -E '^[[:space:]]*(\*|/\*)')"
done
rm -rf $T
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') source scan"
