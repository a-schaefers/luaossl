#!/bin/bash
# Claim C5, run inside one environment (host Ubuntu 24.04, or the 25.10/26.04 chroots).
# Usage: 51-runtime-env.sh <workdir> <cc> <patched-std-flag> <port-base>
# Builds cqueues rel-20261006 and two luaossl modules with the rockspec (luarocks make):
#   fixed     = 950e54e, compiled in C23 (<patched-std-flag>: empty = compiler default)
#   unpatched = e5cd207, compiled with -std=gnu17 (the only way it builds against old headers)
# then for each: start `openssl s_server -www -status_file resp.der` (-www so it does not quit on stdin EOF), connect with topem-client.lua,
# and compare toPEM() output with the PEM encoding of resp.der (expected.pem) and with each other.
set -u
WD=$1; CC=$2; STD=$3; PORT=$4
cd $WD
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') runtime toPEM check in $(grep PRETTY /etc/os-release | cut -d= -f2)"
$CC --version | head -1; openssl version; lua5.4 -v; luarocks --version | head -1
echo "--- build cqueues rel-20261006 ($(git -C cqueues rev-parse HEAD 2>/dev/null || cat cqueues/.commit))"
rm -rf tree-cq
(cd cqueues && luarocks --lua-version=5.4 --tree=$WD/tree-cq make cqueues-20261006.54-0.rockspec CC=$CC CFLAGS="-O2 -fPIC -std=gnu17") > cqueues-build.log 2>&1
echo "cqueues luarocks make exit status: $? (full output in cqueues-build.log)"; tail -n 3 cqueues-build.log
build() { # name rev cflags
  rm -rf src-$1 tree-$1; mkdir src-$1; tar -x -C src-$1 -f luaossl-$2.tar; cp luaossl-20260910-0.rockspec src-$1/
  echo "--- build luaossl $1 = $2 with CC=$CC CFLAGS=\"$3\""
  (cd src-$1 && luarocks --lua-version=5.4 --tree=$WD/tree-$1 make luaossl-20260910-0.rockspec CC=$CC LD=$CC CFLAGS="$3") > build-$1.log 2>&1
  local rc=$?; echo "luaossl $1 luarocks make exit status: $rc"; grep -E "^$CC .*-c src/openssl.c" build-$1.log; grep -E ': error: ' build-$1.log
  ldd tree-$1/lib/lua/5.4/_openssl.so | grep -E 'libssl|libcrypto'
}
build fixed 950e54e "-O2 -fPIC $STD"
build unpatched e5cd207 "-O2 -fPIC -std=gnu17"
n=0
for v in fixed unpatched; do
  n=$((n+1)); port=$((PORT+n))
  echo; echo "--- $(date -u '+%Y-%m-%dT%H:%M:%SZ') run: $v (s_server on 127.0.0.1:$port)"
  openssl s_server -www -accept 127.0.0.1:$port -cert pki/server.pem -key pki/server.key -status_file pki/resp.der -naccept 1 < /dev/null > server-$v.log 2>&1 &
  spid=$!
  for i in $(seq 50); do grep -q ACCEPT server-$v.log && break; sleep 0.1; done
  LUA_PATH="$WD/tree-$v/share/lua/5.4/?.lua;$WD/tree-cq/share/lua/5.4/?.lua;$WD/tree-cq/share/lua/5.4/?/init.lua;;" \
  LUA_CPATH="$WD/tree-$v/lib/lua/5.4/?.so;$WD/tree-cq/lib/lua/5.4/?.so;;" \
    timeout 30 lua5.4 topem-client.lua $port topem-$v.pem; echo "client exit status: $?"
  wait $spid; echo "s_server exit status: $?"; grep -iE 'status|OCSP' server-$v.log | head -3
  if cmp topem-$v.pem pki/expected.pem; then echo "RESULT $v: toPEM() output == expected.pem (PEM of the stapled resp.der) -> MATCH"; else echo "RESULT $v: MISMATCH"; fi
  sha256sum topem-$v.pem
done
echo
if cmp topem-fixed.pem topem-unpatched.pem; then echo "RESULT: fixed (C23) output == unpatched (-std=gnu17) output -> SAME"; else echo "RESULT: fixed vs unpatched DIFFER"; fi
echo "--- toPEM() output:"; cat topem-fixed.pem | head -3; echo "..."; tail -n 2 topem-fixed.pem
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') runtime toPEM check"
