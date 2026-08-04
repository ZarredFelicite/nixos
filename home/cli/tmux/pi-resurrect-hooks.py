#!/usr/bin/env python3
"""Safe Pi-specific enrichment and restore handling for tmux-resurrect."""

from __future__ import annotations

import base64
import json
import os
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any


def normalized_path(path: str, cwd: str | None = None) -> str:
    expanded = os.path.expanduser(path)
    if not os.path.isabs(expanded) and cwd:
        expanded = os.path.join(cwd, expanded)
    return os.path.realpath(expanded)


def same_path(left: str, right: str) -> bool:
    return normalized_path(left) == normalized_path(right)


def tmux_command() -> list[str]:
    socket = os.environ.get("TMUX_SOCKET", os.environ.get("TMUX", "")).split(",", 1)[0]
    return ["tmux", "-S", socket] if socket else ["tmux"]


def tmux(*args: str) -> str:
    try:
        result = subprocess.run(
            [*tmux_command(), *args],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return ""
    return result.stdout.rstrip("\n") if result.returncode == 0 else ""


def b64url(value: str) -> str:
    return base64.urlsafe_b64encode(value.encode()).decode().rstrip("=")


def state_path(pane_id: str) -> Path:
    state_dir = Path(
        os.environ.get(
            "XDG_STATE_HOME", str(Path.home() / ".local" / "state")
        )
    ) / "pi-tmux-sessions"
    return state_dir / f"{b64url(pane_id)}.json"


def read_metadata(pane_id: str) -> dict[str, Any] | None:
    try:
        value = json.loads(state_path(pane_id).read_text())
    except (OSError, ValueError, TypeError):
        return None
    return value if isinstance(value, dict) else None


def command_parts(command: str) -> tuple[list[str], str] | None:
    command = command.strip()
    if command.startswith(":"):
        command = command[1:].lstrip()
    if not command:
        return None
    try:
        parts = shlex.split(command)
    except ValueError:
        return None
    if not parts:
        return None
    if parts[0] == "pi":
        return parts[1:], command
    if len(parts) >= 4 and parts[0] == "cd" and parts[2] == "&&" and parts[3] == "pi":
        return parts[4:], command
    return None


def explicit_session(args: list[str], cwd: str) -> str | None:
    for index, arg in enumerate(args):
        if arg == "--session" and index + 1 < len(args):
            return normalized_path(args[index + 1], cwd)
        if arg.startswith("--session=") and len(arg) > len("--session="):
            return normalized_path(arg.split("=", 1)[1], cwd)
    return None


def valid_session_file(session_file: str) -> bool:
    root = normalized_path("~/.config/pi/agent/sessions")
    candidate = normalized_path(session_file)
    return candidate.startswith(root + os.sep) and os.path.isfile(candidate)


def valid_pi_command(command: str, expected_cwd: str) -> tuple[str, str | None] | None:
    parsed = command_parts(command)
    if parsed is None:
        return None
    args, normalized = parsed
    parts = shlex.split(normalized)
    if parts[0] == "cd" and not same_path(parts[1], expected_cwd):
        return None
    session_file = explicit_session(args, expected_cwd)
    if session_file is not None and not valid_session_file(session_file):
        return None
    return normalized, session_file


def metadata_restart(meta: dict[str, Any], pane_id: str, expected_cwd: str) -> tuple[str, str | None] | None:
    if meta.get("tmuxPane") != pane_id:
        return None
    meta_cwd = meta.get("cwd", "")
    if not meta_cwd or not same_path(meta_cwd, expected_cwd):
        return None
    restart = meta.get("restartCommand", "")
    if not isinstance(restart, str) or not restart:
        return None
    return valid_pi_command(restart, expected_cwd)


def pane_target(fields: list[str]) -> str:
    return f"{fields[1]}:{fields[2]}.{fields[5]}"


def resurrect_cwd(value: str) -> str:
    value = value.lstrip(":")
    try:
        parts = shlex.split(value)
    except ValueError:
        return value
    return parts[0] if len(parts) == 1 else value


def enrich(path: Path) -> None:
    if not path.is_file():
        return
    output: list[str] = []
    with path.open() as source:
        for line in source:
            newline = "\n" if line.endswith("\n") else ""
            fields = line[:-1].split("\t") if newline else line.split("\t")
            if len(fields) < 11 or fields[0] != "pane":
                output.append(line)
                continue

            pane_command = fields[9].lstrip(":").strip()
            saved_command = fields[10].lstrip(":").strip()
            cwd = resurrect_cwd(fields[7])
            saved_pi = valid_pi_command(saved_command, cwd) if saved_command else None
            recognized = pane_command == "pi" or saved_pi is not None
            if not recognized:
                output.append(line)
                continue

            if saved_command and saved_pi is None:
                fields[10] = ":"
            fields[9] = "pi"

            target = pane_target(fields)
            pane_id = tmux("display-message", "-p", "-t", target, "#{pane_id}")
            live_cwd = tmux("display-message", "-p", "-t", target, "#{pane_current_path}")
            if pane_id:
                meta = read_metadata(pane_id)
                restart = metadata_restart(meta, pane_id, cwd) if meta else None
                if restart and (not live_cwd or same_path(live_cwd, cwd)):
                    fields[10] = ":" + restart[0]
            output.append("\t".join(fields) + newline)

    temporary: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=path.parent, prefix=f".{path.name}.", delete=False
        ) as destination:
            temporary = destination.name
            destination.write("".join(output))
            destination.flush()
            os.fsync(destination.fileno())
        os.replace(temporary, path)
        temporary = None
    finally:
        if temporary:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass


def saved_file(path: Path) -> Path | None:
    try:
        resolved = path.resolve(strict=True)
    except OSError:
        return None
    return resolved if resolved.is_file() else None


def current_key(pane_id: str) -> tuple[str, str] | None:
    meta = read_metadata(pane_id)
    if not meta:
        return None
    session_file = meta.get("sessionFile", "")
    cwd = meta.get("cwd", "")
    if not isinstance(session_file, str) or not isinstance(cwd, str) or not cwd:
        return None
    return normalized_path(session_file) if session_file else "", normalized_path(cwd)


def wait_for_pi(target: str) -> None:
    for _ in range(10):
        if command_parts(tmux("display-message", "-p", "-t", target, "#{pane_current_command}")):
            return
        time.sleep(0.1)


def restore(path: Path) -> None:
    source = saved_file(path)
    if source is None:
        return

    with source.open() as saved:
        for line in saved:
            fields = line.rstrip("\n").split("\t")
            if len(fields) < 11 or fields[0] != "pane":
                continue
            saved_command = fields[10].lstrip(":").strip()
            cwd = resurrect_cwd(fields[7])
            has_explicit_session = "--session" in saved_command
            parsed_saved = command_parts(saved_command) if saved_command else None
            explicit = explicit_session(parsed_saved[0], cwd) if parsed_saved else None
            command = valid_pi_command(saved_command, cwd) if saved_command else None

            # An explicit saved session is authoritative. Never replace an invalid
            # explicit session with metadata or a synthesized bare `pi` command.
            if has_explicit_session and command is None:
                continue
            if fields[9].lstrip(":").strip() != "pi" and command is None:
                continue
            target = pane_target(fields)
            current = tmux("display-message", "-p", "-t", target, "#{pane_current_command}")
            pane_id = tmux("display-message", "-p", "-t", target, "#{pane_id}")
            saved_key = (explicit or "", normalized_path(cwd))
            if command is None and pane_id:
                meta = read_metadata(pane_id)
                command = metadata_restart(meta, pane_id, cwd) if meta else None
                if command is not None:
                    saved_key = (
                        explicit_session(shlex.split(command[0]), cwd) or "",
                        normalized_path(cwd),
                    )
            if command is None:
                continue

            if command_parts(current) and pane_id:
                if current_key(pane_id) == saved_key:
                    continue

            restart_command = command[0]
            if not tmux("respawn-pane", "-k", "-t", target, "-c", cwd, restart_command):
                # Fake tmux and real tmux both commonly return no stdout on success;
                # validation below is deliberately independent of that output.
                pass
            wait_for_pi(target)


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in {"enrich", "restore"}:
        print(f"usage: {sys.argv[0]} enrich|restore FILE", file=sys.stderr)
        return 2
    path = Path(sys.argv[2])
    if sys.argv[1] == "enrich":
        enrich(path)
    else:
        restore(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
