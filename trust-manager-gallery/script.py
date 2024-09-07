import http.server
import ssl

ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
ctx.load_cert_chain("/etc/https-server/tls.crt", keyfile="/etc/https-server/tls.key")

srv = http.server.HTTPServer(("", 8443), http.server.SimpleHTTPRequestHandler)
srv.socket = ctx.wrap_socket(srv.socket)
srv.serve_forever()
