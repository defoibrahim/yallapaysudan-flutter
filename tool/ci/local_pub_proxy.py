#!/usr/bin/env python3
"""Minimal pub hosted-repository proxy for CI.

Serves local, not-yet-published packages from tarballs and forwards every other
request to https://pub.dev, so `pana --hosted-url http://127.0.0.1:PORT` can
score a package whose dependency (here yalla_pay_sudan_core) is not on pub.dev
yet. Standard library only.

Usage:
  local_pub_proxy.py PORT NAME=PUBSPEC_JSON:ARCHIVE_TGZ [NAME=...]
"""
import hashlib
import json
import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

UPSTREAM = "https://pub.dev"
CONTENT_TYPE = "application/vnd.pub.v2+json"


def load_local(specs, base_url):
    local = {}
    for spec in specs:
        name, paths = spec.split("=", 1)
        pubspec_path, archive_path = paths.split(":", 1)
        with open(pubspec_path, encoding="utf-8") as f:
            pubspec = json.load(f)
        with open(archive_path, "rb") as f:
            archive = f.read()
        version = pubspec["version"]
        entry = {
            "version": version,
            "pubspec": pubspec,
            "archive_url": f"{base_url}/packages/{name}/versions/{version}.tar.gz",
            "archive_sha256": hashlib.sha256(archive).hexdigest(),
        }
        local[name] = {"listing": {"name": name, "latest": entry, "versions": [entry]},
                       "archive": archive}
    return local


class Handler(BaseHTTPRequestHandler):
    local = {}

    def log_message(self, fmt, *args):
        sys.stderr.write("proxy: " + fmt % args + "\n")

    def _send(self, status, body, content_type):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parts = [p for p in self.path.split("?")[0].split("/") if p]
        # /api/packages/<name> and /api/packages/<name>/advisories
        if len(parts) >= 3 and parts[:2] == ["api", "packages"] and parts[2] in self.local:
            pkg = self.local[parts[2]]
            if len(parts) == 3:
                return self._send(200, json.dumps(pkg["listing"]).encode(), CONTENT_TYPE)
            if parts[3:] == ["advisories"]:
                body = {"advisories": [], "advisoriesUpdated": "2026-01-01T00:00:00.000Z"}
                return self._send(200, json.dumps(body).encode(), CONTENT_TYPE)
            return self._send(404, b"{}", CONTENT_TYPE)
        # /packages/<name>/versions/<version>.tar.gz
        if len(parts) == 4 and parts[0] == "packages" and parts[1] in self.local:
            return self._send(200, self.local[parts[1]]["archive"], "application/octet-stream")
        self._forward()

    def _forward(self):
        headers = {"User-Agent": "ci-local-pub-proxy"}
        if self.headers.get("Accept"):
            headers["Accept"] = self.headers["Accept"]
        req = urllib.request.Request(UPSTREAM + self.path, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                self._send(resp.status, resp.read(),
                           resp.headers.get("Content-Type", "application/octet-stream"))
        except urllib.error.HTTPError as e:
            self._send(e.code, e.read(), e.headers.get("Content-Type", "text/plain"))


def main():
    port = int(sys.argv[1])
    Handler.local = load_local(sys.argv[2:], f"http://127.0.0.1:{port}")
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
