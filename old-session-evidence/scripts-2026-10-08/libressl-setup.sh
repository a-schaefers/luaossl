#!/bin/bash
set -e
cd "$1"
rm -rf portable
GIT_LFS_SKIP_SMUDGE=1 git clone -q --depth 1 https://github.com/libressl/portable portable
cd portable
br=$(cat OPENBSD_BRANCH)
GIT_LFS_SKIP_SMUDGE=1 git clone -q --depth 1 --branch "$br" https://github.com/libressl/openbsd openbsd
./update.sh > update.log 2>&1 || { tail -20 update.log; exit 1; }
echo "OPENBSD_BRANCH=$br VERSION=$(cat VERSION 2>/dev/null)"
ls include/openssl | wc -l
grep -n -A1 'define PEM_write_bio_OCSP_RESPONSE' include/openssl/ocsp.h
