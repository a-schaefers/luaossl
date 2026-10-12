#!/bin/bash
# Build a throwaway CA, a localhost server cert, and a signed OCSP response for it.
set -e
cd "$1"
openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -days 2 -subj "/CN=luaossl test CA" \
  -addext basicConstraints=critical,CA:TRUE -addext keyUsage=critical,keyCertSign,cRLSign,digitalSignature 2>/dev/null
openssl req -newkey rsa:2048 -nodes -keyout server.key -out server.csr -subj "/CN=localhost" 2>/dev/null
printf 'subjectAltName=DNS:localhost,IP:127.0.0.1\nauthorityInfoAccess=OCSP;URI:http://127.0.0.1:1/\n' > ext.cnf
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.pem -days 2 -extfile ext.cnf 2>/dev/null
serial=$(openssl x509 -in server.pem -noout -serial | cut -d= -f2)
exp=$(date -u -d '+2 days' +%y%m%d%H%M%SZ)
printf 'V\t%s\t\t%s\tunknown\t/CN=localhost\n' "$exp" "$serial" > index.txt
openssl ocsp -issuer ca.pem -cert server.pem -no_nonce -reqout req.der
openssl ocsp -index index.txt -rsigner ca.pem -rkey ca.key -CA ca.pem -reqin req.der -respout resp.der -ndays 1 2>&1 | tail -1
openssl ocsp -respin resp.der -CAfile ca.pem -issuer ca.pem -cert server.pem 2>&1 | head -3
{ echo "-----BEGIN OCSP RESPONSE-----"; openssl base64 -in resp.der; echo "-----END OCSP RESPONSE-----"; } > expected.pem
wc -c resp.der expected.pem
