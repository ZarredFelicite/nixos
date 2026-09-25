#!/usr/bin/env python3
"""Fetch AlphaESS inverter telemetry as compact JSON for Quickshell widgets."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, Optional

BASE_URL = "https://openapi.alphaess.com/api"


def _load_env_file() -> None:
    """Populate os.environ from a local .env file when present."""
    try:
        env_path = Path(__file__).resolve().parent.parent / ".env"
    except OSError:
        return
    if not env_path.exists():
        return
    try:
        for line in env_path.read_text().splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if "=" not in stripped:
                continue
            key, value = stripped.split("=", 1)
            key = key.strip()
            if not key or key in os.environ:
                continue
            os.environ[key] = value.strip()
    except OSError:
        pass


_load_env_file()


def _env(name: str) -> Optional[str]:
    value = os.getenv(name)
    return value.strip() if value and value.strip() else None


def _require_env(name: str) -> str:
    value = _env(name)
    if not value:
        raise RuntimeError(
            f"Environment variable {name} is not set."
        )
    return value


class AlphaESSClient:
    """Minimal REST client for the AlphaESS Open API."""

    def __init__(self, app_id: str, app_secret: str, *, base_url: str = BASE_URL, timeout: int = 10) -> None:
        self.app_id = app_id
        self.app_secret = app_secret
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    def _headers(self) -> Dict[str, str]:
        timestamp = str(int(time.time()))
        payload = f"{self.app_id}{self.app_secret}{timestamp}".encode("ascii", "ignore")
        signature = hashlib.sha512(payload).hexdigest()
        return {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Connection": "keep-alive",
            "timestamp": timestamp,
            "timeStamp": timestamp,
            "sign": signature,
            "appId": self.app_id,
        }

    def _request(self, path: str) -> Any:
        url = f"{self.base_url}{path}"
        req = urllib.request.Request(url, headers=self._headers())
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                payload = resp.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            raise RuntimeError(f"HTTP {exc.code} for {url}") from exc
        except urllib.error.URLError as exc:
            raise RuntimeError(f"Network error for {url}: {exc.reason}") from exc

        try:
            data = json.loads(payload)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Invalid JSON from {url}") from exc

        if data.get("msg") != "Success":
            raise RuntimeError(f"API error from {url}: {data.get('msg')}")
        return data.get("data")

    def get_systems(self) -> list[dict[str, Any]]:
        data = self._request("/getEssList")
        return data or []

    def get_last_power(self, sys_sn: str) -> Dict[str, Any]:
        encoded_sn = urllib.parse.quote(sys_sn)
        data = self._request(f"/getLastPowerData?sysSn={encoded_sn}")
        if isinstance(data, list) and data:
            return data[0]
        if isinstance(data, dict):
            return data
        raise RuntimeError("Missing real-time power data")


def _find_system(systems: list[dict[str, Any]], sys_sn: Optional[str]) -> dict[str, Any]:
    if not systems:
        raise RuntimeError("No AlphaESS systems linked to this account")

    if sys_sn:
        for system in systems:
            if system.get("sysSn", "").lower() == sys_sn.lower():
                return system
        raise RuntimeError(f"System serial {sys_sn} not found in account")

    return systems[0]


def _as_float(value: Any) -> Optional[float]:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    try:
        return float(str(value))
    except (TypeError, ValueError):
        return None


def gather_snapshot(*, sys_sn: Optional[str], timeout: int) -> Dict[str, Any]:
    app_id = _require_env("ALPHAESS_APP_ID")
    app_secret = _require_env("ALPHAESS_APP_SECRET")
    client = AlphaESSClient(app_id, app_secret, timeout=timeout)

    systems = client.get_systems()
    system = _find_system(systems, sys_sn or _env("ALPHAESS_SYS_SN"))
    serial = system.get("sysSn")
    if not serial:
        raise RuntimeError("System missing serial number")

    power = client.get_last_power(serial)

    result = {
        "serial": serial,
        "model": system.get("minv"),
        "system_name": system.get("sysName") or system.get("sysSn"),
        "battery_model": system.get("mbat"),
        "timestamp": int(time.time()),
        "power_watts": {
            "solar": _as_float(power.get("ppv")),
            "battery": _as_float(power.get("pbat")),
            "load": _as_float(power.get("pload")),
            "grid": _as_float(power.get("pgrid")),
        },
        "battery_soc": _as_float(power.get("soc")),
    }

    return result


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="AlphaESS JSON snapshot helper")
    parser.add_argument("--sys-sn", help="Specific inverter serial to query")
    parser.add_argument("--timeout", type=int, default=10, help="HTTP timeout in seconds")
    args = parser.parse_args(argv)

    try:
        snapshot = gather_snapshot(sys_sn=args.sys_sn, timeout=args.timeout)
    except Exception as exc:  # pylint: disable=broad-except
        print(f"alphaess_status.py: {exc}", file=sys.stderr)
        return 1

    json.dump(snapshot, sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
