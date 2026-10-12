#!/bin/bash
# Claim in the message: "`luarocks install luaossl` fails with GCC 15.2 and OpenSSL 3.5.3".
# The other runs used `luarocks make` with the same rockspec on a git checkout; this one runs the
# literal command, which downloads the rockspec from luarocks.org and the source zip from GitHub.
# Ubuntu 25.10 (OpenSSL 3.5.3) is expected to fail; Ubuntu 26.04 (OpenSSL 3.5.5) is the control.
set -u
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') literal luarocks install luaossl"
for suite in questing resolute; do
  root=/srv/$suite
  echo; echo "################ chroot $suite"
  chroot $root sh -c 'grep PRETTY /etc/os-release; gcc --version | head -1; printf "gcc default __STDC_VERSION__: "; echo __STDC_VERSION__ | gcc -E -P -x c - | tail -1; openssl version; dpkg-query -W libssl-dev luarocks'
  rm -rf $root/build/tree-install $root/build/install-tmp; mkdir -p $root/build/install-tmp
  echo "--- $(date -u '+%Y-%m-%dT%H:%M:%SZ') luarocks --lua-version=5.4 --tree=/build/tree-install install luaossl"
  chroot $root sh -c 'cd /build/install-tmp && TMPDIR=/build/install-tmp luarocks --lua-version=5.4 --tree=/build/tree-install install luaossl 2>&1'
  rc=$?
  echo "RESULT: $suite literal 'luarocks install luaossl' exit status = $rc ($( [ $rc = 0 ] && echo INSTALLED || echo FAILED ))"
  chroot $root sh -c 'luarocks --lua-version=5.4 --tree=/build/tree-install list 2>/dev/null | grep -A1 "^luaossl"'
  chroot $root sh -c 'luarocks --lua-version=5.4 download --rockspec luaossl >/dev/null 2>&1 && ls luaossl-*.rockspec && sha256sum luaossl-*.rockspec && rm -f luaossl-*.rockspec' 2>&1
done
echo "rockspec used by the luarocks make runs: $(sha256sum /srv/verify/src/rockspec/luaossl-20260910-0.rockspec)"
echo; echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') literal luarocks install luaossl"
