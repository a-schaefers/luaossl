#!/bin/bash
# Fetch OpenSSL sources used for the header matrix (1.1.1w and 4.0.3).
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') fetch openssl"
set -x
cd /srv/verify/src
git clone -q --depth 1 --branch OpenSSL_1_1_1w https://github.com/openssl/openssl openssl-1.1.1w
git clone -q --depth 1 --branch openssl-4.0.3 https://github.com/openssl/openssl openssl-4.0.3
git -C openssl-1.1.1w log -1 --format='%H %d %cd'
git -C openssl-4.0.3 log -1 --format='%H %d %cd'
set +x
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') fetch openssl"
