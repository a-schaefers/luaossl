#!/bin/bash
# Fixture for claim C5: a test CA, a server cert for 127.0.0.1/localhost, and a signed OCSP
# response (status "good") for that cert, made with the host's openssl 3.0.13.
# Also writes the expected PEM encoding of the DER response, computed independently in Python.
set -eu
P=/srv/verify/work/pki
rm -rf $P; mkdir -p $P; cd $P
echo "=== START $(date -u '+%Y-%m-%dT%H:%M:%SZ') OCSP fixture ($(openssl version))"
set -x
openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -days 30 -subj "/CN=luaossl audit test CA" \
  -addext basicConstraints=critical,CA:TRUE -addext keyUsage=critical,keyCertSign,cRLSign 2>/dev/null
openssl req -newkey rsa:2048 -nodes -keyout server.key -out server.csr -subj "/CN=localhost" 2>/dev/null
printf 'subjectAltName=DNS:localhost,IP:127.0.0.1\nauthorityInfoAccess=OCSP;URI:http://127.0.0.1:8888\n' > ext.cnf
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.pem -days 30 -extfile ext.cnf 2>/dev/null
{ set +x; } 2>/dev/null
serial=$(openssl x509 -in server.pem -noout -serial | cut -d= -f2)
enddate=$(date -u -d "$(openssl x509 -in server.pem -noout -enddate | cut -d= -f2)" +%y%m%d%H%M%SZ)
subject=$(openssl x509 -in server.pem -noout -subject -nameopt compat | sed 's/^subject=//')
printf 'V\t%s\t\t%s\tunknown\t%s\n' "$enddate" "$serial" "$subject" > index.txt
echo "index.txt:"; cat index.txt
set -x
openssl ocsp -issuer ca.pem -cert server.pem -no_nonce -reqout req.der
openssl ocsp -index index.txt -rsigner ca.pem -rkey ca.key -CA ca.pem -reqin req.der -respout resp.der -ndays 30
openssl ocsp -respin resp.der -issuer ca.pem -cert server.pem -CAfile ca.pem -no_nonce
{ set +x; } 2>/dev/null
python3 -I - resp.der expected.pem <<'PY'
import base64, sys
der = open(sys.argv[1], 'rb').read()
b64 = base64.b64encode(der).decode()
lines = [b64[i:i+64] for i in range(0, len(b64), 64)]
open(sys.argv[2], 'w').write('-----BEGIN OCSP RESPONSE-----\n' + '\n'.join(lines) + '\n-----END OCSP RESPONSE-----\n')
print('expected.pem written from', len(der), 'DER bytes')
PY
sha256sum resp.der expected.pem
echo "=== END $(date -u '+%Y-%m-%dT%H:%M:%SZ') OCSP fixture"
