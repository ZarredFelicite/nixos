#!/usr/bin/env python3
"""Return a compact status snapshot from the local Pi Dashboard REST API."""

from __future__ import annotations

import argparse
import json
from typing import Any
from urllib.request import urlopen


def is_subagent_session(session: Any) -> bool:
    """Reject dashboard identity fields plus the local launcher name fallback."""
    if not isinstance(session, dict):
        return False
    name = session.get("name")
    return (
        session.get("kind") == "subagent"
        or bool(session.get("parentSessionId"))
        or bool(session.get("subagentJobId"))
        or (isinstance(name, str) and name.startswith("subagent-"))
    )


def build_status(health: dict[str, Any], rows: list[Any], limit: int) -> dict[str, Any]:
    valid_rows = [row for row in rows if isinstance(row, dict)]
    rows_by_id = {str(row.get("id")): row for row in valid_rows if row.get("id")}
    regular_rows = [row for row in valid_rows if not is_subagent_session(row)]
    active_parent_ids: set[str] = set()
    child_activity: dict[str, float] = {}

    # Attribute active child work to the nearest regular ancestor. Subagent rows
    # remain private and never appear in the output model themselves.
    for child in valid_rows:
        if not is_subagent_session(child) or child.get("status") not in {"streaming", "resuming"}:
            continue
        parent_id = str(child.get("parentSessionId") or "")
        visited: set[str] = set()
        while parent_id and parent_id not in visited:
            visited.add(parent_id)
            parent = rows_by_id.get(parent_id)
            if not parent:
                break
            if not is_subagent_session(parent):
                active_parent_ids.add(parent_id)
                child_activity[parent_id] = max(
                    child_activity.get(parent_id, 0),
                    float(child.get("lastActivityAt") or 0),
                )
                break
            parent_id = str(parent.get("parentSessionId") or "")

    connected = [
        row
        for row in regular_rows
        if row.get("status") != "ended" or str(row.get("id") or "") in active_parent_ids
    ]

    def needs_attention(row: dict[str, object]) -> bool:
        return row.get("status") == "error" or row.get("currentTool") == "ask_user"

    def working(row: dict[str, object]) -> bool:
        return (
            row.get("status") in {"streaming", "resuming"}
            or str(row.get("id") or "") in active_parent_ids
        ) and not needs_attention(row)

    interesting = [row for row in connected if needs_attention(row) or working(row)]
    interesting.sort(
        key=lambda row: (
            2 if needs_attention(row) else 1,
            max(
                float(row.get("lastActivityAt") or 0),
                child_activity.get(str(row.get("id") or ""), 0),
            ),
        ),
        reverse=True,
    )

    sessions = []
    for row in interesting[: max(0, limit)]:
        model = str(row.get("model") or "")
        parent_has_active_child = str(row.get("id") or "") in active_parent_ids
        sessions.append(
            {
                "id": str(row.get("id") or ""),
                "name": str(row.get("name") or row.get("firstMessage") or "Unnamed session"),
                "status": "needs-you" if needs_attention(row) else "working",
                "model": model.rsplit("/", 1)[-1],
                "tool": str(row.get("currentTool") or ("subagent" if parent_has_active_child else "")),
            }
        )

    server = health.get("server") if isinstance(health.get("server"), dict) else {}
    total = server.get("totalSessions")
    if isinstance(total, int):
        total_sessions = max(0, total - sum(is_subagent_session(row) for row in rows))
    else:
        total_sessions = len(regular_rows)
    return {
        "ok": bool(health.get("ok")),
        "version": str(health.get("version") or ""),
        "connected": len(connected),
        "working": sum(working(row) for row in connected),
        "needsAttention": sum(needs_attention(row) for row in connected),
        "idle": sum(not working(row) and not needs_attention(row) for row in connected),
        "unread": sum(row.get("unread") is True for row in connected),
        "totalSessions": total_sessions,
        "sessions": sessions,
    }


def fetch_json(url: str, timeout: float) -> object:
    with urlopen(url, timeout=timeout) as response:
        return json.load(response)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default="http://100.64.1.150:8000")
    parser.add_argument("--timeout", type=float, default=3.0)
    parser.add_argument("--limit", type=int, default=3)
    args = parser.parse_args()

    base = args.url.rstrip("/")
    health = fetch_json(f"{base}/api/health", args.timeout)
    response = fetch_json(f"{base}/api/sessions", args.timeout)
    if not isinstance(health, dict) or not isinstance(response, dict):
        raise ValueError("dashboard returned an invalid response")

    rows = response.get("data", [])
    if not isinstance(rows, list):
        raise ValueError("dashboard session response has no data array")

    result = build_status(health, rows, args.limit)
    print(json.dumps(result, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
