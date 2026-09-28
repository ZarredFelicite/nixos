#!/usr/bin/env python3
"""Atomically update selected Pi notify extension settings."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import tempfile

BOOL_KEYS = {"enabled", "desktop", "sound", "tts", "visualAlert", "showFinalMessagePills", "dashboardQuestionsListenerEnabled"}
DURATION_KEYS = {"minDurationMs", "visualAlertAfterMs", "ttsAfterMs"}


def validate(updates: object) -> dict[str, object]:
    if not isinstance(updates, dict):
        raise ValueError("update payload must be a JSON object")

    validated: dict[str, object] = {}
    for key, value in updates.items():
        if key in BOOL_KEYS:
            if not isinstance(value, bool):
                raise ValueError(f"{key} must be a boolean")
        elif key in DURATION_KEYS:
            if isinstance(value, bool) or not isinstance(value, int) or value < 0:
                raise ValueError(f"{key} must be a non-negative integer")
        else:
            raise ValueError(f"unsupported setting: {key}")
        validated[key] = value
    return validated


def update_config(path: Path, updates: dict[str, object]) -> None:
    current: dict[str, object] = {}
    if path.exists():
        loaded = json.loads(path.read_text())
        if not isinstance(loaded, dict):
            raise ValueError("existing config must be a JSON object")
        current = loaded

    current.update(updates)
    path.parent.mkdir(parents=True, exist_ok=True)

    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as temporary:
            json.dump(current, temporary, indent=2)
            temporary.write("\n")
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--path", type=Path, required=True)
    parser.add_argument("--update", required=True, help="JSON object of settings to merge")
    args = parser.parse_args()

    update_config(args.path, validate(json.loads(args.update)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
