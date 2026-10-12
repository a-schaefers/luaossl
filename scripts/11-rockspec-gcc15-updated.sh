#!/bin/bash
# Same as 10-rockspec-gcc15.sh, but after enabling the -updates and -security pockets in both chroots,
# i.e. a fully updated Ubuntu 25.10 / 26.04 (the earlier session's chroots had libssl-dev
# 3.5.3-1ubuntu3.4 and 3.5.5-1ubuntu3.7; the plain release pockets ship 3.5.3-1ubuntu2 / 3.5.5-1ubuntu3).
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') update chroots"
for suite in questing resolute; do
  root=/srv/$suite
  echo "deb http://archive.ubuntu.com/ubuntu $suite-updates main universe" > $root/etc/apt/sources.list.d/updates.list
  echo "deb http://security.ubuntu.com/ubuntu $suite-security main universe" >> $root/etc/apt/sources.list.d/updates.list
  chroot $root env DEBIAN_FRONTEND=noninteractive apt-get update -q > /dev/null
  chroot $root env DEBIAN_FRONTEND=noninteractive apt-get -y -q upgrade > /dev/null
  echo "$suite: $(chroot $root dpkg-query -W -f='${Package} ${Version}  ' gcc-15 libssl-dev openssl)"
  chroot $root grep -n -A1 'define PEM_write_bio_OCSP_RESPONSE' /usr/include/openssl/ocsp.h
done
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') update chroots"
/srv/verify/scripts/10-rockspec-gcc15.sh
