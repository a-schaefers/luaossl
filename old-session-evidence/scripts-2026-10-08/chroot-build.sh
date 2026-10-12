#!/bin/sh
# runs inside a chroot: luarocks make of a luaossl tree, the way `luarocks install luaossl` builds it
# usage: chroot-build.sh <tree-name> [extra luarocks vars...]
set -u
name=$1; shift
cd /work && rm -rf "/work/build-$name" && cp -a "/work/$name" "/work/build-$name" && cd "/work/build-$name"
luarocks make --tree "/work/tree-$name" /work/luaossl-20260910-0.rockspec "$@" > "/work/log-$name.txt" 2>&1
rc=$?
echo "rc=$rc"
grep -E 'error:|Error:' "/work/log-$name.txt" | head -5
exit 0
