"""
One-shot Shopify OAuth install helper.

Runs a tiny local HTTP server, opens the Shopify authorize URL in your browser,
catches the callback, exchanges the code for an offline access token, and writes
the token back into .env as SHOPIFY_ACCESS_TOKEN.

Re-run this whenever the app's scopes change — e.g. the production move to
`read_all_orders,read_customers,read_inventory,read_orders,read_products`. After
updating the scopes in the Shopify app config (create version + release), set
SHOPIFY_SCOPES in .env to match, then run this to mint a token carrying them.

Prerequisites:
  - .env populated with CLIENT_ID, CLIENT_SECRET, SHOP_DOMAIN, SCOPES, REDIRECT_URI
  - The Shopify app's "Allowed redirection URL(s)" includes the REDIRECT_URI

Run (from code/etl/):
    python -m shopify_dwh.oauth_install
"""

from __future__ import annotations

import secrets
import sys
import urllib.parse
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer

import httpx

from shopify_dwh.config import DEFAULT_ENV_PATH, ShopifyConfig, load_settings

# Filled in by main() — kept at module scope so the callback handler can read them.
_STATE = secrets.token_urlsafe(32)
_captured: dict[str, str | None] = {"code": None, "state": None, "error": None}
_redirect_path = "/callback"


def build_authorize_url(cfg: ShopifyConfig) -> str:
    params = {
        "client_id": cfg.client_id,
        "scope": cfg.scopes,
        "redirect_uri": cfg.redirect_uri,
        "state": _STATE,
        "grant_options[]": "",
    }
    return f"https://{cfg.shop_domain}/admin/oauth/authorize?{urllib.parse.urlencode(params)}"


def exchange_code_for_token(cfg: ShopifyConfig, code: str) -> str:
    url = f"https://{cfg.shop_domain}/admin/oauth/access_token"
    payload = {"client_id": cfg.client_id, "client_secret": cfg.client_secret, "code": code}
    resp = httpx.post(url, json=payload, timeout=30.0)
    resp.raise_for_status()
    return resp.json()["access_token"]


def write_token_to_env(token: str) -> None:
    lines = DEFAULT_ENV_PATH.read_text(encoding="utf-8").splitlines()
    updated = False
    for i, line in enumerate(lines):
        if line.startswith("SHOPIFY_ACCESS_TOKEN="):
            lines[i] = f"SHOPIFY_ACCESS_TOKEN={token}"
            updated = True
            break
    if not updated:
        lines.append(f"SHOPIFY_ACCESS_TOKEN={token}")
    DEFAULT_ENV_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


class CallbackHandler(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != _redirect_path:
            self.send_response(404)
            self.end_headers()
            return

        params = urllib.parse.parse_qs(parsed.query)
        _captured["code"] = params.get("code", [None])[0]
        _captured["state"] = params.get("state", [None])[0]
        _captured["error"] = params.get("error", [None])[0]

        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        if _captured["error"]:
            body = f"<h1>OAuth error</h1><p>{_captured['error']}</p>"
        else:
            body = "<h1>Got it.</h1><p>You can close this tab.</p>"
        self.wfile.write(body.encode("utf-8"))

    def log_message(self, *_args, **_kwargs):
        pass  # quiet


def main() -> int:
    global _redirect_path
    cfg = load_settings().shopify

    if not all([cfg.client_id, cfg.client_secret, cfg.scopes, cfg.redirect_uri]):
        print(
            "Missing one of CLIENT_ID / CLIENT_SECRET / SCOPES / REDIRECT_URI in .env",
            file=sys.stderr,
        )
        return 2

    parsed_redirect = urllib.parse.urlparse(cfg.redirect_uri)
    _redirect_path = parsed_redirect.path or "/callback"
    host = parsed_redirect.hostname or "localhost"
    port = parsed_redirect.port or 3000

    authorize_url = build_authorize_url(cfg)
    print("\nOpening browser to:")
    print(f"  {authorize_url}\n")
    print(f"Listening for callback on {cfg.redirect_uri} ...")
    webbrowser.open(authorize_url)

    server = HTTPServer((host, port), CallbackHandler)
    try:
        while _captured["code"] is None and _captured["error"] is None:
            server.handle_request()
    finally:
        server.server_close()

    if _captured["error"]:
        print(f"\nOAuth error: {_captured['error']}", file=sys.stderr)
        return 1

    if _captured["state"] != _STATE:
        print("\nState mismatch — possible CSRF. Aborting.", file=sys.stderr)
        return 1

    print("\nCode received. Exchanging for access token...")
    token = exchange_code_for_token(cfg, _captured["code"])
    write_token_to_env(token)
    print(f"\nSuccess. Token written to {DEFAULT_ENV_PATH}")
    print(f"  Token starts with: {token[:8]}...")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
