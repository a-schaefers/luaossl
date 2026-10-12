#!/bin/bash
# Build a minimal Ubuntu chroot with the distro's own GCC and OpenSSL.
# Usage: 02-setup-chroot.sh <suite>   (questing = 25.10, resolute = 26.04)
suite=$1; root=/srv/$suite
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') chroot setup $suite"
set -x
debootstrap --variant=minbase --components=main,universe "$suite" "$root" http://archive.ubuntu.com/ubuntu /usr/share/debootstrap/scripts/gutsy || exit 1
cp /etc/resolv.conf "$root/etc/resolv.conf"
mountpoint -q "$root/proc" || mount -t proc proc "$root/proc"
mountpoint -q "$root/dev" || mount --bind /dev "$root/dev"
cat "$root/etc/apt/sources.list"
chroot "$root" env DEBIAN_FRONTEND=noninteractive apt-get update -q
chroot "$root" env DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    gcc libc6-dev libssl-dev openssl lua5.4 liblua5.4-dev luarocks m4 make git ca-certificates binutils unzip
set +x
echo "--- versions ($suite)"
chroot "$root" sh -c 'grep PRETTY /etc/os-release; gcc --version | head -1; echo "gcc default -std: $(echo __STDC_VERSION__ | gcc -E -P -x c - | tail -1)"; openssl version; lua5.4 -v; luarocks --version | head -1'
chroot "$root" dpkg-query -W gcc gcc-15 libssl-dev openssl lua5.4 liblua5.4-dev luarocks
chroot "$root" grep -n -A2 'define PEM_write_bio_OCSP_RESPONSE' /usr/include/openssl/ocsp.h
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') chroot setup $suite"
