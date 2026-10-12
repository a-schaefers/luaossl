#!/bin/bash
# Appended the last section of logs/60-openssl-version-facts.log (run once, 2026-10-12 07:25:42Z, as a
# one-off command; saved here verbatim so it can be rerun). Shows OpenSSL commit 0b7afd6d's message,
# whether it is an ancestor of the openssl-4.0.0 tag, and the files it changed, from the treeless clone.
cd /srv/verify/src/osslrefs && { echo; echo "--- $(date -u '+%Y-%m-%dT%H:%M:%SZ') OpenSSL commit 0b7afd6d (history fetched with --filter=tree:0 from github.com/openssl/openssl)"; git show -s --format='commit %H%nAuthor: %an <%ae>%nAuthorDate: %aI%nCommitDate: %cI%n%n%B' 0b7afd6d; printf 'ancestor of openssl-4.0.0 tag: '; git merge-base --is-ancestor 0b7afd6d openssl-4.0.0 && echo yes || echo no; echo "files changed:"; timeout 300 git show --stat=200 --format= 0b7afd6d 2>&1 | tail -n 12; } >> /srv/verify/logs/60-openssl-version-facts.log 2>&1; tail -n 32 /srv/verify/logs/60-openssl-version-facts.log
