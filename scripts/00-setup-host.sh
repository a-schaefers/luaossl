#!/bin/bash
# Host (Ubuntu 24.04) toolchain setup for the luaossl C23 audit.
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') host setup"
set -x
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q debootstrap gcc-14 lua5.4 liblua5.4-dev luarocks m4
set +x
echo "--- versions"
cat /etc/os-release | grep PRETTY
gcc-14 --version | head -1
clang-18 --version | head -1
lua5.4 -v
luarocks --version | head -1
openssl version
dpkg -l libssl-dev gcc-14 clang-18 lua5.4 liblua5.4-dev debootstrap | grep ^ii | awk '{print $2, $3}'
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') host setup"
