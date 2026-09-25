#!/usr/bin/env python3
import base64
import json
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

AUTH_FILE = Path.home() / ".codex" / "auth.json"
TOKEN_URL = "https://auth.openai.com/oauth/token"
USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"
CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann"


def b64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


def read_auth() -> dict:
    if not AUTH_FILE.exists():
        raise RuntimeError("~/.codex/auth.json not found")
    return json.loads(AUTH_FILE.read_text())


def write_auth(auth: dict) -> None:
    AUTH_FILE.write_text(json.dumps(auth, indent=2) + "\n")


def parse_access_token_claims(access_token: str) -> dict:
    parts = access_token.split(".")
    if len(parts) < 2:
        raise RuntimeError("Invalid access token format")
    return json.loads(b64url_decode(parts[1]).decode())


def build_usage_headers(access_token: str) -> dict:
    claims = parse_access_token_claims(access_token)
    auth_claims = claims.get("https://api.openai.com/auth", {})
    account_id = auth_claims.get("chatgpt_account_id")

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Accept": "application/json",
    }
    if account_id:
        headers["chatgpt-account-id"] = account_id
    return headers


def refresh_tokens(auth: dict) -> dict:
    refresh_token = ((auth.get("tokens") or {}).get("refresh_token") or "").strip()
    if not refresh_token:
        raise RuntimeError("No Codex refresh token found; run `codex login`")

    body = urllib.parse.urlencode({
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": CLIENT_ID,
    }).encode()
    req = urllib.request.Request(
        TOKEN_URL,
        data=body,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            payload = json.load(resp)
    except urllib.error.HTTPError as exc:
        message = "Token refresh failed"
        try:
            payload = json.loads(exc.read().decode())
            error = payload.get("error") or {}
            message = error.get("message") or message
        except Exception:
            pass
        raise RuntimeError(message) from exc

    tokens = auth.setdefault("tokens", {})
    tokens["access_token"] = payload["access_token"]
    if payload.get("refresh_token"):
        tokens["refresh_token"] = payload["refresh_token"]
    if payload.get("id_token"):
        tokens["id_token"] = payload["id_token"]
    auth["last_refresh"] = int(time.time())
    write_auth(auth)
    return auth


def fetch_usage_payload(access_token: str) -> dict:
    req = urllib.request.Request(USAGE_URL, headers=build_usage_headers(access_token))
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.load(resp)


def normalize_window(window: dict | None) -> dict | None:
    if not isinstance(window, dict):
        return None
    return {
        "used_percent": float(window.get("used_percent", 0.0) or 0.0),
        "remaining_percent": max(0.0, 100.0 - float(window.get("used_percent", 0.0) or 0.0)),
        "limit_window_seconds": int(window.get("limit_window_seconds", 0) or 0),
        "limit_window_minutes": int((window.get("limit_window_seconds", 0) or 0) / 60) if window.get("limit_window_seconds") else None,
        "reset_after_seconds": int(window.get("reset_after_seconds", 0) or 0),
        "reset_at": int(window.get("reset_at", 0) or 0) or None,
    }


def normalize_payload(payload: dict) -> dict:
    rate_limit = payload.get("rate_limit") or {}
    credits = payload.get("credits") or {}
    return {
        "ok": True,
        "plan_type": payload.get("plan_type", "unknown"),
        "primary": normalize_window(rate_limit.get("primary_window")),
        "secondary": normalize_window(rate_limit.get("secondary_window")),
        "credits": {
            "has_credits": bool(credits.get("has_credits", False)),
            "unlimited": bool(credits.get("unlimited", False)),
            "balance": credits.get("balance"),
        } if isinstance(credits, dict) else None,
        "fetched_at": int(time.time()),
    }


def main() -> int:
    try:
        auth = read_auth()
        access_token = ((auth.get("tokens") or {}).get("access_token") or "").strip()
        if not access_token:
            raise RuntimeError("No Codex access token found; run `codex login`")

        try:
            payload = fetch_usage_payload(access_token)
        except urllib.error.HTTPError as exc:
            if exc.code != 401:
                body = exc.read().decode(errors="ignore")[:400]
                raise RuntimeError(f"Usage request failed ({exc.code}): {body or exc.reason}") from exc
            auth = refresh_tokens(auth)
            access_token = ((auth.get("tokens") or {}).get("access_token") or "").strip()
            payload = fetch_usage_payload(access_token)

        print(json.dumps(normalize_payload(payload)))
        return 0
    except Exception as exc:
        print(json.dumps({
            "ok": False,
            "error": str(exc),
            "fetched_at": int(time.time()),
        }))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
