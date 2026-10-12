-- Claim C5 client: connect to 127.0.0.1:<port> with cqueues + luaossl, ask the server to staple
-- an OCSP response, then write ssl:getTLSextStatusOCSPResp():toPEM() to <outfile>.
local port, outfile = assert(tonumber(arg[1]), "port"), assert(arg[2], "outfile")
local cqueues = require"cqueues"
local socket = require"cqueues.socket"
local openssl = require"openssl"
local context = require"openssl.ssl.context"
local ssl = require"openssl.ssl".new(context.new("TLS", false))
assert(ssl:setTLSextStatusType("ocsp"))
print(("luaossl %s | built against %s | running %s"):format(
	package.searchpath("_openssl", package.cpath), openssl.VERSION_TEXT, openssl.version(0)))
print(("cqueues %s %s"):format(package.searchpath("_cqueues", package.cpath), cqueues.VERSION))
local cq = cqueues.new()
cq:wrap(function()
	local s = assert(socket.connect("127.0.0.1", port))
	assert(s:starttls(ssl, 10))
	local resp = assert(ssl:getTLSextStatusOCSPResp(), "server stapled no OCSP response")
	local pem = resp:toPEM()
	local f = assert(io.open(outfile, "wb")); f:write(pem); f:close()
	print(("handshake done (TLS version 0x%04x); toPEM() returned %d bytes -> %s"):format(ssl:getVersion(), #pem, outfile))
	s:close()
end)
assert(cq:loop())
