#!/bin/bash
# Claims C1/C2: build luaossl with its own 20260910-0 rockspec (luarocks make, i.e. the same
# compile/link commands `luarocks install luaossl` runs) using each distro's GCC 15.2 in its
# default C23 mode. Ubuntu 25.10 = OpenSSL 3.5.3, Ubuntu 26.04 = OpenSSL 3.5.5.
# before = e5cd207 (upstream rel-20260910), after = 950e54e (PR #222 head), plus 63f211b (first version).
set -u
REPO=/home/claude/luaossl
ROCKSPEC=/srv/verify/src/rockspec/luaossl-20260910-0.rockspec
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') rockspec builds with GCC 15.2"
echo "rockspec sha256: $(sha256sum $ROCKSPEC | cut -d' ' -f1)"
for suite in questing resolute; do
  root=/srv/$suite
  echo; echo "################ chroot $suite"
  chroot $root sh -c 'grep PRETTY /etc/os-release; gcc --version | head -1; printf "gcc default __STDC_VERSION__: "; echo __STDC_VERSION__ | gcc -E -P -x c - | tail -1; openssl version; dpkg-query -W libssl-dev lua5.4 luarocks'
  for rev in e5cd207ccacf2b4201c9d1f3bc2ebb6b4b673e32 63f211b056405835235db7fc2c4699e96eb53681 950e54e40733fc3b34becad4d3a00ec3a3f562eb; do
    short=${rev:0:7}
    echo; echo "======== $suite @ $rev ($(git -C $REPO log -1 --format=%s $rev))"
    echo "--- $(date -u '+%Y-%m-%dT%H:%M:%SZ') src/openssl.c from git: sha256 $(git -C $REPO show $rev:src/openssl.c | sha256sum | cut -d' ' -f1)"
    rm -rf $root/build/luaossl $root/build/tree-$short; mkdir -p $root/build/luaossl
    git -C $REPO archive $rev | tar -x -C $root/build/luaossl
    cp $ROCKSPEC $root/build/luaossl/
    set -x
    chroot $root sh -c "cd /build/luaossl && luarocks --lua-version=5.4 --tree=/build/tree-$short make luaossl-20260910-0.rockspec"
    rc=$?
    { set +x; } 2>/dev/null
    echo "RESULT: $suite $short luarocks make exit status = $rc ($( [ $rc = 0 ] && echo BUILD OK || echo BUILD FAILED ))"
    if [ $rc = 0 ]; then
      chroot $root sh -c "cd / && eval \"\$(luarocks --lua-version=5.4 --tree=/build/tree-$short path)\" && lua5.4 -e 'local r = require[[openssl.ocsp.response]]; local mt = debug.getregistry()[ [[OCSP_RESPONSE*]] ]; print([[module loads from]], package.searchpath([[_openssl]], package.cpath), [[| OCSP_RESPONSE:toPEM is a]], mt and type(mt.__index.toPEM))'"
    fi
  done
done
echo; echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') rockspec builds with GCC 15.2"
