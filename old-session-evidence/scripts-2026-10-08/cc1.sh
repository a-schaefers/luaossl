#!/bin/bash
# Compile luaossl's src/openssl.c the way the 20260910-0 rockspec does
# (builtin backend, config.h.guess patch emulated with -include).
# usage: cc1.sh <srcdir> <cc> <std|-> <openssl-incdir> <lua-incdir> [extra cflags...]
src=$1; cc=$2; std=$3; sslinc=$4; luainc=$5; shift 5
stdflag=""; [ "$std" != "-" ] && stdflag="-std=$std"
out=$(mktemp -d)
$cc -O2 -fPIC $stdflag "$@" -I"$luainc" -include "$src/config.h.guess" \
  -D_REENTRANT -D_THREAD_SAFE -DCOMPAT53_PREFIX=luaossl -D_GNU_SOURCE \
  -I"$sslinc" -c "$src/src/openssl.c" -o "$out/openssl.o" 2> "$out/err.txt"
rc=$?
nerr=$(grep -c ' error: ' "$out/err.txt"); nwarn=$(grep -c ' warning: ' "$out/err.txt")
echo "rc=$rc errors=$nerr warnings=$nwarn obj=$out/openssl.o log=$out/err.txt"
