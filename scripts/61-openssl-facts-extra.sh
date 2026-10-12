#!/bin/bash
# Extends 60-openssl-version-facts.sh for two parts of claim C7 it did not cover:
#  (a) "every earlier release ... including all of 1.1.1": every public 1.0.2, 1.1.0 and 1.1.1 release tag;
#  (b) "backported to 3.0.19, 3.3.6, 3.4.4, 3.5.5 and 3.6.1": the commit on each release branch, between the
#      last old-cast tag and the first new-cast tag, that changed the cast (subject, PR, cherry-pick line, files).
set -u
O=/srv/verify/src/osslrefs   # treeless clone (--filter=tree:0) of github.com/openssl/openssl
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') OpenSSL facts, part 2"
T=$(mktemp -d)
classify() { local l=$(grep -A1 'define PEM_write_bio_OCSP_RESPONSE' "$1" | tr -s ' \t\n\\' ' ')
  case "$l" in *'(int (*)())'*) echo "OLD cast (int (*)())";; *'(i2d_of_void *)'*) echo "NEW cast (i2d_of_void *)";; '') echo "macro not found";; *) echo "other: $l";; esac; }
git ls-remote --tags https://github.com/openssl/openssl > $T/tags.txt
echo "--- (a) 1.0.2 / 1.1.0 / 1.1.1 release tags (header: crypto/ocsp/ocsp.h in 1.0.2, include/openssl/ocsp.h after)"
printf '%-16s %-42s %-26s %s\n' tag commit result "git blob of header"
for tag in $(sed -nE 's#.*refs/tags/(OpenSSL_1_(0_2|1_0|1_1)[a-z]?)$#\1#p' $T/tags.txt | sort -V); do
  commit=$(grep -E "refs/tags/$tag\^\{\}$" $T/tags.txt | cut -f1); [ -z "$commit" ] && commit=$(grep -E "refs/tags/$tag$" $T/tags.txt | cut -f1)
  case $tag in OpenSSL_1_0_2*) path=crypto/ocsp/ocsp.h;; *) path=include/openssl/ocsp.h;; esac
  curl -sSf "https://raw.githubusercontent.com/openssl/openssl/$tag/$path" -o $T/h 2>/dev/null || { printf '%-16s %-42s %s\n' $tag "$commit" "FETCH FAILED"; continue; }
  printf '%-16s %-42s %-26s %s\n' $tag "$commit" "$(classify $T/h)" "$(git hash-object $T/h)"
done
echo
echo "--- (b) the commit that changed the cast on each release branch"
pairs="openssl-3.0.18:openssl-3.0.19 openssl-3.3.5:openssl-3.3.6 openssl-3.4.3:openssl-3.4.4 openssl-3.5.4:openssl-3.5.5 openssl-3.6.0:openssl-3.6.1"
refs=""; for p in $pairs; do refs="$refs refs/tags/${p%%:*}:refs/tags/${p%%:*} refs/tags/${p##*:}:refs/tags/${p##*:}"; done
git -C $O fetch -q --filter=tree:0 origin $refs 2>&1 | tail -n 2
for p in $pairs; do
  a=${p%%:*}; b=${p##*:}
  echo; echo "## $a..$b"
  hits=$(git -C $O log --format=%H --grep='C23' "$a..$b")
  [ -z "$hits" ] && echo "   no commit mentioning C23 in this range"
  for h in $hits; do
    git -C $O show -s --format='   %H%n   author %an, %aI; committed %cI%n   subject: %s' $h
    git -C $O show -s --format=%b $h | grep -E 'Fixes|Merged from|cherry picked' | sed 's/^/   /'
    git -C $O show --format= --stat $h | sed 's/^/   /'
  done
done
echo; echo "--- master's original for comparison"
git -C $O show -s --format='   %H  %s  (committed %cI)' 0b7afd6d
rm -rf $T
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') OpenSSL facts, part 2"
