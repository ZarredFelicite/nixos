#!/usr/bin/env python3
from __future__ import annotations

"""Emit realtime peak levels for a PipeWire node."""

import argparse
import json
import math
import signal
import struct
import subprocess
import sys
from typing import Optional


def build_command(
    node_target: str, rate: int, channels: int, props: Optional[str]
) -> list[str]:
    cmd: list[str] = [
        "pw-cat",
        "--record",
        "--target",
        node_target,
        "--format",
        "f32",
        "--channels",
        str(channels),
        "--rate",
        str(rate),
        "--raw",
        "-",
    ]
    if props:
        cmd.extend(["--properties", props])
    return cmd


def clamp(value: float, min_value: float = 0.0, max_value: float = 1.0) -> float:
    return max(min_value, min(max_value, value))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--node", required=True, help="PipeWire node id or name to monitor"
    )
    parser.add_argument(
        "--interval", type=float, default=0.12, help="Seconds between samples"
    )
    parser.add_argument(
        "--rate", type=int, default=4000, help="Sample rate for the monitor stream"
    )
    parser.add_argument(
        "--channels", type=int, default=2, help="Number of channels to read"
    )
    parser.add_argument(
        "--decay",
        type=float,
        default=0.08,
        help="Linear decay applied between updates (0-1)",
    )
    parser.add_argument(
        "--monitor",
        action="store_true",
        help="Tap monitor ports for sink playback levels",
    )
    args = parser.parse_args()

    node_target = args.node

    channels = max(1, int(args.channels))
    sample_rate = max(500, int(args.rate))
    interval = max(0.02, float(args.interval))
    decay = clamp(float(args.decay), 0.0, 1.0)

    frames_per_chunk = max(1, int(sample_rate * interval))
    chunk_frame_count = frames_per_chunk * channels
    chunk_bytes = chunk_frame_count * 4  # f32 samples

    props_str: Optional[str] = None
    if args.monitor:
        props_str = json.dumps(
            {
                "stream.capture.sink": True,
                "node.passive": True,
                "media.name": "QS Peak Monitor",
            }
        )

    cmd = build_command(node_target, sample_rate, channels, props_str)
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            bufsize=chunk_bytes,
        )
    except FileNotFoundError:
        print("0.0", flush=True)
        return 1

    stream = proc.stdout
    if stream is None:
        print("0.0", flush=True)
        return 1

    def _cleanup(signum: int, frame: Optional[object]) -> None:
        if proc.poll() is None:
            proc.terminate()

    signal.signal(signal.SIGTERM, _cleanup)
    signal.signal(signal.SIGINT, _cleanup)

    level = 0.0
    buffer = bytearray()
    try:
        while True:
            chunk = stream.read(chunk_bytes)
            if not chunk:
                if proc.poll() is not None:
                    break
                continue
            buffer.extend(chunk)
            while len(buffer) >= chunk_bytes:
                frame = buffer[:chunk_bytes]
                del buffer[:chunk_bytes]
                if not frame:
                    continue
                try:
                    samples = struct.unpack("<%sf" % chunk_frame_count, frame)
                except struct.error:
                    continue
                peak = max(abs(v) for v in samples)
                if math.isnan(peak):
                    continue
                peak = clamp(peak, 0.0, 1.5)
                if peak > level:
                    level = peak
                else:
                    level = max(0.0, level - decay)
                print(f"{clamp(level):.4f}", flush=True)
    finally:
        _cleanup(0, None)

    if level > 0.0:
        print("0.0", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
