-- Fetch a stapled OCSP response over TLS and check OCSP_RESPONSE:toPEM().
-- usage: lua ocsp-topem.lua <port> <expected.pem>
local cqueues = require "cqueues"
local socket = require "cqueues.socket"
local context = require "openssl.ssl.context"
local ssl = require "openssl.ssl"
local openssl = require "openssl"

local port, expected_file = assert(tonumber(arg[1])), assert(arg[2])

local conn = ssl.new(context.new("TLS", false))
assert(conn:setTLSextStatusType("ocsp"))
conn:setHostName("localhost")

local sock = assert(socket.connect("127.0.0.1", port))
local cq = cqueues.new()
cq:wrap(function() assert(sock:starttls(conn)) end)
assert(cq:loop())

local resp = assert(conn:getTLSextStatusOCSPResp(), "server did not staple an OCSP response")
local pem = resp:toPEM()
local f = assert(io.open(expected_file, "rb"))
local expected = f:read("*a")
f:close()

print(("built against %s, running %s"):format(openssl.VERSION_TEXT, openssl.version and openssl.version(openssl.VERSION) or "?"))
assert(pem == expected, "toPEM output differs from the expected PEM:\n" .. pem)
print(("toPEM: %d bytes, identical to the PEM encoding of the stapled DER"):format(#pem))
assert(resp:tostring():find("OCSP Response Status: successful", 1, true))
assert(resp:getBasic())
print("tostring/getBasic: OK")
sock:close()
