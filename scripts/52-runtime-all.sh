#!/bin/bash
# Driver for claim C5: prepare the same inputs for the host (OpenSSL 3.0.13, GCC 14.2 with -std=gnu23)
# and the chroots (OpenSSL 3.5.3 / 3.5.5, GCC 15.2 default C23), then run 51-runtime-env.sh in each.
set -u
REPO=/home/claude/luaossl
prep() { # dir
  rm -rf $1; mkdir -p $1
  for r in 950e54e e5cd207; do git -C $REPO archive -o $1/luaossl-$r.tar $r; done
  cp /srv/verify/src/rockspec/luaossl-20260910-0.rockspec /srv/verify/scripts/topem-client.lua /srv/verify/scripts/51-runtime-env.sh $1/
  cp -r /srv/verify/src/cqueues $1/cqueues; git -C /srv/verify/src/cqueues rev-parse HEAD > $1/cqueues/.commit
  cp /srv/verify/src/cq-rockspec/cqueues-20261006.54-0.rockspec $1/cqueues/
  cp -r /srv/verify/work/pki $1/pki
}
prep /srv/verify/work/rt-host
/srv/verify/work/rt-host/51-runtime-env.sh /srv/verify/work/rt-host gcc-14 -std=gnu23 4430
for suite in questing resolute; do
  echo; echo "################################ chroot $suite"
  prep /srv/$suite/build/rt
  chroot /srv/$suite /build/rt/51-runtime-env.sh /build/rt gcc "" $([ $suite = questing ] && echo 4440 || echo 4450)
done
