"""
One-shot Shopify OAuth install helper.

Runs a tiny local HTTP server, opens the Shopify authorize URL in your browser,
catches the callback, exchanges the code for an offline access token, and writes
the token back into .env as SHOPIFY_ACCESS_TOKEN.

Prerequisites:
  - .env populated with CLIENT_ID, CLIENT_SECRET, SHOP_DOMAIN, SCOPES, REDIRECT_URI
  - The Shopify app's "Allowed redirection URL(s)" includes the REDIRECT_URI
    (default: http://localhost:3000/callback)

Run:
    python oauth_install.py
"""

import os
import secrets
import sys
import urllib.parse
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import httpx
from dotenv import load_dotenv

ENV_PATH = Path(__file__).parent / ".env"
load_dotenv(ENV_PATH)

SHOP_DOMAIN = os.environ["SHOPIFY_SHOP_DOMAIN"]
CLIENT_ID = os.environ["SHOPIFY_CLIENT_ID"]
CLIENT_SECRET = os.environ["SHOPIFY_CLIENT_SECRET"]
SCOPES = os.environ["SHOPIFY_SCOPES"]
REDIRECT_URI = os.environ["SHOPIFY_REDIRECT_URI"]

STATE = secrets.token_urlsafe(32)
captured = {"code": None, "state": None, "error": None}


def build_authorize_url() -> str:
    params = {
        "client_id": CLIENT_ID,
        "scope": SCOPES,
        "redirect_uri": REDIRECT_URI,
        "state": STATE,
        "grant_options[]": "",
    }
    return f"https://{SHOP_DOMAIN}/admin/oauth/authorize?{urllib.parse.urlencode(params)}"


def exchange_code_for_token(code: str) -> str:
    url = f"https://{SHOP_DOMAIN}/admin/oauth/access_token"
    payload = {
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "code": code,
    }
    resp = httpx.post(url, json=payload, timeout=30.0)
    resp.raise_for_status()
    return resp.json()["access_token"]


def write_token_to_env(token: str) -> None:
    lines = ENV_PATH.read_text(encoding="utf-8").splitlines()
    updated = False
    for i, line in enumerate(lines):
        if line.startswith("SHOPIFY_ACCESS_TOKEN="):
            lines[i] = f"SHOPIFY_ACCESS_TOKEN={token}"
            updated = True
            break
    if not updated:
        lines.append(f"SHOPIFY_ACCESS_TOKEN={token}")
    ENV_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


class CallbackHandler(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != urllib.parse.urlparse(REDIRECT_URI).path:
            self.send_response(404)
            self.end_headers()
            return

        params = urllib.parse.parse_qs(parsed.query)
        captured["code"] = params.get("code", [None])[0]
        captured["state"] = params.get("state", [None])[0]
        captured["error"] = params.get("error", [None])[0]

        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        if captured["error"]:
            body = f"<h1>OAuth error</h1><p>{captured['error']}</p>"
        else:
            body = "<h1>Got it.</h1><p>You can close this tab.</p>"
        self.wfile.write(body.encode("utf-8"))

    def log_message(self, *_args, **_kwargs):
        pass  # quiet


def main() -> int:
    parsed_redirect = urllib.parse.urlparse(REDIRECT_URI)
    host = parsed_redirect.hostname or "localhost"
    port = parsed_redirect.port or 3000

    authorize_url = build_authorize_url()
    print("\nOpening browser to:")
    print(f"  {authorize_url}\n")
    print(f"Listening for callback on {REDIRECT_URI} ...")
    webbrowser.open(authorize_url)

    server = HTTPServer((host, port), CallbackHandler)
    try:
        while captured["code"] is None and captured["error"] is None:
            server.handle_request()
    finally:
        server.server_close()

    if captured["error"]:
        print(f"\nOAuth error: {captured['error']}", file=sys.stderr)
        return 1

    if captured["state"] != STATE:
        print("\nState mismatch — possible CSRF. Aborting.", file=sys.stderr)
        return 1

    print("\nCode received. Exchanging for access token...")
    token = exchange_code_for_token(captured["code"])
    write_token_to_env(token)
    print(f"\nSuccess. Token written to {ENV_PATH}")
    print(f"  Token starts with: {token[:8]}...")
    return 0


if __name__ == "__main__":
    sys.exit(main())
