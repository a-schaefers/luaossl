#!/bin/bash
# usage: run-ocsp-test.sh <lua> <pkidir> <port> [LUA_PATH LUA_CPATH via env]
lua=$1; pki=$2; port=$3
openssl s_server -accept 127.0.0.1:$port -cert $pki/server.pem -key $pki/server.key -status_file $pki/resp.der -naccept 1 -quiet > /tmp/s_server.$port.log 2>&1 &
spid=$!
for i in $(seq 1 50); do (exec 3<>/dev/tcp/127.0.0.1/$port) 2>/dev/null && break; sleep 0.1; done
# the readiness probe above consumed the single accept; restart the server for the real client
wait $spid 2>/dev/null
openssl s_server -accept 127.0.0.1:$port -cert $pki/server.pem -key $pki/server.key -status_file $pki/resp.der -naccept 1 -quiet > /tmp/s_server.$port.log 2>&1 &
spid=$!
sleep 0.5
$lua "$(dirname "$0")/ocsp-topem.lua" $port $pki/expected.pem
rc=$?
kill $spid 2>/dev/null; wait $spid 2>/dev/null
exit $rc
