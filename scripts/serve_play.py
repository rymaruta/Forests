#!/usr/bin/env python3
import http.server, socketserver, os
os.chdir("/workspace/play")
PORT = 8765
Handler = http.server.SimpleHTTPRequestHandler
Handler.extensions_map.update({
    ".wasm": "application/wasm",
    ".js": "application/javascript",
    ".mjs": "application/javascript",
    ".json": "application/json",
    ".pck": "application/octet-stream",
    ".png": "image/png",
    ".html": "text/html",
})
socketserver.TCPServer.allow_reuse_address = True
print(f"Serving /workspace/play on {PORT}", flush=True)
with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    httpd.serve_forever()
