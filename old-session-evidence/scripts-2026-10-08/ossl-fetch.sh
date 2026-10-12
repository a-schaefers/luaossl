#!/bin/bash
# usage: ossl-fetch.sh <tag> <dir> ; shallow clone + configure + generate headers
set -e
tag=$1; dir=$2
GIT_LFS_SKIP_SMUDGE=1 git clone -q --depth 1 --branch "$tag" https://github.com/openssl/openssl "$dir"
cd "$dir"
if [ -x ./Configure ]; then ./Configure linux-x86_64 no-tests --prefix="$dir-inst" --libdir=lib > configure.log 2>&1; fi
make -s build_generated > gen.log 2>&1 || true
echo "headers ready: $(ls include/openssl/*.h | wc -l) files; opensslv: $(grep -m1 -E 'OPENSSL_VERSION_TEXT|define OPENSSL_VERSION_STR' include/openssl/opensslv.h)"
