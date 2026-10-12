#!/bin/bash
# Claim C7 (background facts in the commit message): which OpenSSL releases have the old
# `(int (*)())` cast in PEM_write_bio_OCSP_RESPONSE and which have `(i2d_of_void *)`; and LibreSSL.
# Reads each release tag's ocsp header from raw.githubusercontent.com; prints the git blob id too.
set -u
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') OpenSSL/LibreSSL header facts"
T=$(mktemp -d)
classify() { # file
  local l=$(grep -A1 'define PEM_write_bio_OCSP_RESPONSE' "$1" | tr -s ' \t\n\\' ' ')
  case "$l" in *'(int (*)())'*) echo "OLD cast (int (*)())";; *'(i2d_of_void *)'*) echo "NEW cast (i2d_of_void *)";; '') echo "macro not found";; *) echo "other: $l";; esac
}
printf '%-16s %-42s %-26s %s\n' tag commit result "git blob of header"
git ls-remote --tags https://github.com/openssl/openssl > $T/tags.txt
for tag in $(cat /srv/verify/work/ossl-release-tags.txt) master; do
  case $tag in OpenSSL_1_1_1*) path=include/openssl/ocsp.h;; *) path=include/openssl/ocsp.h.in;; esac
  if [ $tag = master ]; then commit=$(git ls-remote https://github.com/openssl/openssl refs/heads/master | cut -f1); ref=$commit
  else commit=$(grep -E "refs/tags/$tag\^\{\}$" $T/tags.txt | cut -f1); [ -z "$commit" ] && commit=$(grep -E "refs/tags/$tag$" $T/tags.txt | cut -f1); ref=$tag; fi
  curl -sSf "https://raw.githubusercontent.com/openssl/openssl/$ref/$path" -o $T/h 2>/dev/null || { printf '%-16s %-42s %s\n' $tag $commit "FETCH FAILED ($path)"; continue; }
  printf '%-16s %-42s %-26s %s\n' $tag "$commit" "$(classify $T/h)" "$(git hash-object $T/h)"
done
echo
echo "--- LibreSSL (OpenBSD libcrypto ocsp.h, via libressl/openbsd)"
git ls-remote --tags https://github.com/libressl/portable 'refs/tags/v4.3*' | grep -v '\^{}' | sed 's#.*refs/tags/##' | sort -V | tr '\n' ' '; echo
br=$(curl -sSf https://raw.githubusercontent.com/libressl/portable/v4.3.3/OPENBSD_BRANCH); echo "libressl/portable v4.3.3 OPENBSD_BRANCH = $br"
for ref in "$br" master; do
  c=$(git ls-remote https://github.com/libressl/openbsd "refs/heads/$ref" "refs/tags/$ref" | head -1 | cut -f1)
  curl -sSf "https://raw.githubusercontent.com/libressl/openbsd/$ref/src/lib/libcrypto/ocsp/ocsp.h" -o $T/l && \
    printf 'libressl/openbsd %-22s %-42s %-26s %s\n' "$ref" "$c" "$(classify $T/l)" "$(git hash-object $T/l)" || echo "libressl/openbsd $ref: FETCH FAILED"
  grep -n -A2 'define PEM_write_bio_OCSP_RESPONSE' $T/l
done
rm -rf $T
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') OpenSSL/LibreSSL header facts"
