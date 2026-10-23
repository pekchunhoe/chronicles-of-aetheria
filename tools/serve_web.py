"""Serve the real Web export over HTTP with correct WASM/PCK MIME types."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class GameHandler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm", ".pck": "application/octet-stream", ".js": "text/javascript"}

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--bind", default="127.0.0.1")
    options = parser.parse_args()
    folder = Path(__file__).resolve().parent.parent / "web"
    if not (folder / "index.html").is_file():
        parser.error("Run tools/export_web.ps1 first")
    server = ThreadingHTTPServer((options.bind, options.port), partial(GameHandler, directory=str(folder)))
    print(f"Serving Aetheria at http://{options.bind}:{options.port}/ (Ctrl+C to stop)", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
