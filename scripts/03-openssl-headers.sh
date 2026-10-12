#!/bin/bash
# Generate the public headers of OpenSSL 1.1.1w and 4.0.3 (headers only, no library build).
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') openssl headers"
set -x
cd /srv/verify/src/openssl-1.1.1w && ./config no-shared no-asm > /dev/null && make -s include/openssl/opensslconf.h
cd /srv/verify/src/openssl-4.0.3 && ./Configure no-shared no-asm > /dev/null && make -s build_generated > /dev/null
set +x
for d in /srv/verify/src/openssl-1.1.1w /srv/verify/src/openssl-4.0.3; do
  echo "--- $d (git $(git -C $d rev-parse HEAD))"
  grep -h 'define OPENSSL_VERSION_TEXT' $d/include/openssl/opensslv.h
  grep -h -A2 'define PEM_write_bio_OCSP_RESPONSE' $d/include/openssl/ocsp.h
done
echo "--- host /usr/include (libssl-dev $(dpkg-query -W -f='${Version}' libssl-dev))"
grep -h 'define OPENSSL_VERSION_TEXT' /usr/include/openssl/opensslv.h
grep -h -A2 'define PEM_write_bio_OCSP_RESPONSE' /usr/include/openssl/ocsp.h
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') openssl headers"
