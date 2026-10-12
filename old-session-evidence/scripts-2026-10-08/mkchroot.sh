#!/bin/bash
# usage: mkchroot.sh <suite> <dir>
set -e
suite=$1; dir=$2
debootstrap --variant=minbase --components=main,universe "$suite" "$dir" http://archive.ubuntu.com/ubuntu /usr/share/debootstrap/scripts/gutsy
cat > "$dir/etc/apt/sources.list" <<SRC
deb http://archive.ubuntu.com/ubuntu $suite main universe
deb http://archive.ubuntu.com/ubuntu $suite-updates main universe
deb http://archive.ubuntu.com/ubuntu $suite-security main universe
SRC
mount --bind /proc "$dir/proc" 2>/dev/null || mount -t proc proc "$dir/proc" || true
mount --bind /dev "$dir/dev" 2>/dev/null || true
chroot "$dir" apt-get update -qq
DEBIAN_FRONTEND=noninteractive chroot "$dir" apt-get install -y -qq --no-install-recommends gcc libc6-dev make libssl-dev openssl lua5.4 liblua5.4-dev luarocks ca-certificates unzip git >/dev/null
chroot "$dir" sh -c 'gcc --version | head -1; dpkg -l libssl-dev | tail -1; luarocks --version | head -1'
echo DONE
