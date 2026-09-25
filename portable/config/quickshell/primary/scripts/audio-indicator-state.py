#!/usr/bin/env python3
"""Validate ownership of Quickshell's STT/TTS process markers."""

from __future__ import annotations

import argparse
import fcntl
import os
import stat
from pathlib import Path
from typing import Optional

MARKER_FORMAT = "audio-marker-v2"
MAX_MARKER_BYTES = 256
MAX_PROC_BYTES = 64 * 1024
KINDS = {
    "recording": ("stt", Path("/tmp/audio_recording_running.tmp"), Path("/home/zarred/scripts/stt/stt")),
    "tts-active": ("tts-active", Path("/tmp/quickshell-tts-active"), Path("/home/zarred/scripts/tts/tts")),
    "tts-playing": ("tts-playing", Path("/tmp/quickshell-tts-playing"), Path("/home/zarred/scripts/tts/tts")),
}


def marker_lock_path(marker: Path) -> Path:
    return marker.with_name(f".{marker.name}.owner.lock")


def read_bounded(path: Path, maximum: int) -> bytes:
    with path.open("rb") as handle:
        contents = handle.read(maximum + 1)
    if len(contents) > maximum:
        raise ValueError("oversized")
    return contents


def parse_proc_stat(contents: str) -> Optional[tuple[str, str]]:
    try:
        fields = contents.rsplit(")", 1)[1].split()
        return fields[0], fields[19]
    except (IndexError, ValueError):
        return None


def process_identity(proc_root: Path, pid: int) -> Optional[tuple[str, str]]:
    try:
        parsed = parse_proc_stat(read_bounded(proc_root / str(pid) / "stat", 4096).decode("ascii"))
    except (OSError, UnicodeError, ValueError):
        return None
    if parsed is None or parsed[0] in {"Z", "X"}:
        return None
    return parsed


def command_matches(proc_root: Path, pid: int, expected_script: Path) -> bool:
    try:
        arguments = read_bounded(proc_root / str(pid) / "cmdline", MAX_PROC_BYTES).split(b"\0")
    except (OSError, ValueError):
        return False
    expected = expected_script.resolve()
    for raw in arguments:
        if not raw:
            continue
        try:
            argument = Path(os.fsdecode(raw))
        except UnicodeError:
            continue
        if argument == expected_script or argument.resolve() == expected:
            return True
    return False


def process_start_wall_time(proc_root: Path, start_ticks: str) -> Optional[float]:
    try:
        boot_line = next(
            line for line in (proc_root / "stat").read_text(encoding="ascii").splitlines()
            if line.startswith("btime ")
        )
        boot_time = int(boot_line.split()[1])
        return boot_time + int(start_ticks) / os.sysconf("SC_CLK_TCK")
    except (OSError, StopIteration, ValueError):
        return None


def valid_process(
    proc_root: Path,
    pid: int,
    expected_start: Optional[str],
    expected_script: Path,
    marker_mtime: float,
) -> bool:
    first = process_identity(proc_root, pid)
    if first is None or not command_matches(proc_root, pid, expected_script):
        return False
    second = process_identity(proc_root, pid)
    if second is None or second[1] != first[1]:
        return False
    if expected_start is not None:
        return first[1] == expected_start
    started = process_start_wall_time(proc_root, first[1])
    return started is not None and marker_mtime + 1.0 >= started


def legacy_empty_tts_is_live(proc_root: Path, expected_script: Path, marker_mtime: float) -> bool:
    try:
        entries = tuple(proc_root.iterdir())
    except OSError:
        return True
    for entry in entries:
        if entry.name.isdecimal() and valid_process(
            proc_root, int(entry.name), None, expected_script, marker_mtime
        ):
            return True
    return False


def parse_marker(contents: bytes) -> Optional[tuple[str, int, Optional[str]]]:
    try:
        value = contents.decode("ascii").strip()
    except UnicodeError:
        return None
    fields = value.split()
    if len(fields) == 4 and fields[0] == MARKER_FORMAT:
        kind, pid_text, start_ticks = fields[1:]
        if pid_text.isdecimal() and start_ticks.isdecimal():
            return kind, int(pid_text), start_ticks
        return None
    if len(fields) == 1 and fields[0].isdecimal():
        return "legacy", int(fields[0]), None
    return None


def queue_lock_is_held(queue_lock: Path) -> bool:
    try:
        queue_lock.touch(mode=0o600, exist_ok=True)
        with queue_lock.open("r+") as handle:
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return True
    except OSError:
        return True
    return False


def marker_is_active(
    mode: str,
    *,
    marker: Optional[Path] = None,
    proc_root: Path = Path("/proc"),
    expected_script: Optional[Path] = None,
    queue_lock: Path = Path("/tmp/tts-queue.lock"),
) -> bool:
    expected_kind, default_marker, default_script = KINDS[mode]
    marker = marker or default_marker
    expected_script = expected_script or default_script
    if mode == "tts-active" and queue_lock_is_held(queue_lock):
        return True

    lock_path = marker_lock_path(marker)
    try:
        lock_path.touch(mode=0o600, exist_ok=True)
        with lock_path.open("r+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            try:
                marker_stat = marker.lstat()
                if not stat.S_ISREG(marker_stat.st_mode) or marker_stat.st_uid != os.getuid():
                    return True
                contents = read_bounded(marker, MAX_MARKER_BYTES)
            except FileNotFoundError:
                return False
            except (OSError, ValueError):
                return True

            parsed = parse_marker(contents)
            if parsed is not None:
                kind, pid, start_ticks = parsed
                kind_matches = kind in {expected_kind, "legacy"}
                active = kind_matches and valid_process(
                    proc_root, pid, start_ticks, expected_script, marker_stat.st_mtime
                )
            elif not contents and mode.startswith("tts-"):
                active = legacy_empty_tts_is_live(proc_root, expected_script, marker_stat.st_mtime)
            else:
                active = False

            if not active:
                try:
                    current_stat = marker.lstat()
                    if (
                        current_stat.st_dev == marker_stat.st_dev
                        and current_stat.st_ino == marker_stat.st_ino
                        and read_bounded(marker, MAX_MARKER_BYTES) == contents
                    ):
                        marker.unlink()
                except (FileNotFoundError, OSError, ValueError):
                    pass
            return active
    except OSError:
        return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=KINDS)
    args = parser.parse_args()
    print("active" if marker_is_active(args.mode) else "inactive")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
