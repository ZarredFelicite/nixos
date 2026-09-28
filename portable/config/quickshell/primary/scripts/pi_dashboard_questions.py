#!/usr/bin/env python3
"""Bridge the Pi Dashboard PromptBus over a small, sanitized line protocol."""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from typing import Any
from urllib.request import Request, urlopen

import websocket

MAX_ID = 200
MAX_TEXT = 1200
MAX_MESSAGE = 1000
MAX_OPTION = 300
MAX_OPTIONS = 30
MAX_BATCH_QUESTIONS = 20
MAX_FINAL_TEXT = 2400
METHODS = {"confirm", "select", "multiselect", "input", "editor", "batch"}

CONTROL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
FENCED_BLOCK_RE = re.compile(r"```.*?```", re.DOTALL)
SECRET_RE = re.compile(
    r"(?i)\b(api[_-]?key|access[_-]?token|auth[_-]?token|token|password|passwd|secret)\b"
    r'''["']?(?:\s*[:=]\s*|\s+)["']?([^\s,;}"']+)'''
)
BEARER_RE = re.compile(r"(?i)\bbearer\s+[A-Za-z0-9._~+/=-]+")
TOKEN_RE = re.compile(r"\b(?:sk|gh[pousr]|xox[baprs])[-_][A-Za-z0-9_-]{12,}\b")
UNIX_PATH_RE = re.compile(r"(?<![\w.:/])(?:~|/(?!/))(?:[^\s<>|]+/)*[^\s<>|,;:)]*")
WINDOWS_PATH_RE = re.compile(r"(?i)\b[A-Z]:\\(?:[^\s<>|]+\\)*[^\s<>|,;:)]*")
RAW_HTML_RE = re.compile(r"<!--.*?-->|<(?!https?://|mailto:)/?[A-Za-z][^>]*>", re.DOTALL)
MARKDOWN_IMAGE_RE = re.compile(
    r"!\[([^\]\n]{0,240})\]\(\s*(?:<[^>\n]*>|[^)\s]+)(?:\s+[\"'][^)]*[\"'])?\s*\)"
)
MARKDOWN_REFERENCE_IMAGE_RE = re.compile(r"!\[([^\]\n]{0,240})\]\[[^\]\n]*\]")
UNORDERED_LIST_LINE_RE = re.compile(r"^(?P<indent>[ \t]*)[-+*][ \t]+(?P<content>\S.*)$")
THEMATIC_BREAK_RE = re.compile(r"^[ \t]*(?:[-*_][ \t]*){3,}$")
MARKDOWN_LINK_RE = re.compile(
    r"(?<!!)\[([^\]\n]{0,240})\]\(\s*(?:<([^>\n]*)>|([^\s)\n]+))"
    r"(?:\s+[\"'][^)]*[\"'])?\s*\)"
)
SAFE_LINK_RE = re.compile(r"(?i)^(?:https?://|mailto:)")


def safe_string(value: Any, maximum: int) -> str:
    return value.strip()[:maximum] if isinstance(value, str) else ""


def safe_name(value: Any) -> str:
    return value.strip() if isinstance(value, str) else ""


def safe_options(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    result: list[str] = []
    for item in value:
        option = safe_string(item, MAX_OPTION)
        if option:
            result.append(option)
        if len(result) >= MAX_OPTIONS:
            break
    return result


def is_subagent_session(session: Any) -> bool:
    """Reject dashboard identity fields and local subagent launcher fallbacks."""
    if not isinstance(session, dict):
        return False
    name = session.get("name")
    launcher_root = "/tmp/pi-subagents"
    launcher_path = any(
        isinstance(session.get(field), str)
        and (
            session[field] == launcher_root
            or session[field].startswith(f"{launcher_root}/")
        )
        for field in ("sessionFile", "sessionDir")
    )
    return (
        session.get("kind") == "subagent"
        or bool(session.get("parentSessionId"))
        or bool(session.get("subagentJobId"))
        or (isinstance(name, str) and name.startswith("subagent-"))
        or launcher_path
    )


def is_watching_status(status: Any) -> bool:
    return status in {"streaming", "resuming"}


def sanitize_session(session: Any) -> dict[str, Any] | None:
    if not isinstance(session, dict) or is_subagent_session(session):
        return None
    session_id = safe_string(session.get("id"), MAX_ID)
    if not session_id or session.get("status") == "ended":
        return None
    return {
        "id": session_id,
        "name": safe_name(session.get("name")) or "Pi session",
        # currentTool is cleared before ask_user opens, so follow sessions while
        # their model turn is still live instead of relying on that field.
        "watching": is_watching_status(session.get("status")),
    }


def sanitize_batch_questions(value: Any) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    result: list[dict[str, Any]] = []
    for item in value[:MAX_BATCH_QUESTIONS]:
        if not isinstance(item, dict):
            continue
        method = item.get("method")
        title = safe_string(item.get("title") or item.get("question") or item.get("header"), MAX_TEXT)
        if method not in METHODS - {"batch"} or not title:
            continue
        result.append(
            {
                "method": method,
                "title": title,
                "message": safe_string(item.get("message"), MAX_MESSAGE),
                "options": safe_options(item.get("options")),
                "placeholder": safe_string(item.get("placeholder"), MAX_OPTION),
            }
        )
    return result


def sanitize_prompt(message: Any, sessions: dict[str, dict[str, Any]]) -> dict[str, Any] | None:
    """Keep only fields needed by the questions widget."""
    if not isinstance(message, dict) or message.get("placement") == "widget-bar":
        return None
    session_id = safe_string(message.get("sessionId"), MAX_ID)
    prompt_id = safe_string(message.get("promptId"), MAX_ID)
    session = sessions.get(session_id)
    prompt = message.get("prompt")
    if not session or is_subagent_session(session) or not isinstance(prompt, dict):
        return None

    method = prompt.get("type")
    title = safe_string(prompt.get("question"), MAX_TEXT)
    metadata = prompt.get("metadata") if isinstance(prompt.get("metadata"), dict) else {}
    batch_questions = sanitize_batch_questions(metadata.get("questions")) if method == "batch" else []
    if method not in METHODS or not title or not prompt_id:
        return None
    if method == "batch" and not batch_questions:
        return None

    return {
        "id": prompt_id,
        "sessionId": session_id,
        "sessionName": session["name"],
        "type": method,
        "question": title,
        "message": safe_string(metadata.get("message"), MAX_MESSAGE),
        "options": safe_options(prompt.get("options")),
        "placeholder": safe_string(prompt.get("defaultValue"), MAX_OPTION),
        "batchQuestions": batch_questions,
    }


def sanitize_markdown(text: str) -> str:
    """Keep display-safe Markdown while preventing resource-bearing constructs."""
    text = MARKDOWN_IMAGE_RE.sub(lambda match: match.group(1), text)
    text = MARKDOWN_REFERENCE_IMAGE_RE.sub(lambda match: match.group(1), text)

    def keep_link(match: re.Match[str]) -> str:
        label = match.group(1)
        destination = match.group(2) if match.group(2) is not None else match.group(3)
        return match.group(0) if destination and SAFE_LINK_RE.match(destination) else label

    text = MARKDOWN_LINK_RE.sub(keep_link, text)
    return RAW_HTML_RE.sub("", text)


def compact_markdown_lists(text: str) -> str:
    """Render tight unordered lists as plain Markdown lines with hard breaks.

    Qt's MarkdownText parser adds list-block spacing that cannot be controlled by
    Text.lineHeight or lineHeightMode. Replacing only the marker at the trusted
    boundary keeps the item text and all remaining safe Markdown unchanged while
    avoiding that parser-generated list layout.
    """
    compacted: list[str] = []
    for line in text.splitlines(keepends=True):
        ending = ""
        body = line
        if line.endswith("\r\n"):
            body, ending = line[:-2], "\r\n"
        elif line.endswith(("\n", "\r")):
            body, ending = line[:-1], line[-1]
        match = UNORDERED_LIST_LINE_RE.match(body)
        if not match or THEMATIC_BREAK_RE.match(body):
            compacted.append(line)
            continue
        replacement = f"{match.group('indent')}• {match.group('content')}"
        compacted.append(replacement + (f"  {ending}" if ending else ""))
    return "".join(compacted)


def sanitize_assistant_text(value: Any) -> str:
    """Return bounded display text while redacting common secret/config surfaces."""
    if not isinstance(value, str):
        return ""
    text = CONTROL_RE.sub("", value)
    text = FENCED_BLOCK_RE.sub("[code/config omitted]", text)
    text = sanitize_markdown(text)
    text = BEARER_RE.sub("Bearer [redacted]", text)
    text = TOKEN_RE.sub("[credential redacted]", text)
    text = SECRET_RE.sub(lambda match: f"{match.group(1)}=[redacted]", text)
    text = WINDOWS_PATH_RE.sub("[path redacted]", text)
    text = UNIX_PATH_RE.sub("[path redacted]", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    return compact_markdown_lists(text)[:MAX_FINAL_TEXT]


def sanitize_final_event(message: Any, sessions: dict[str, dict[str, Any]]) -> dict[str, str] | None:
    """Allowlist only a live finalized assistant turn from a regular session."""
    if not isinstance(message, dict) or message.get("type") != "event":
        return None
    session_id = safe_string(message.get("sessionId"), MAX_ID)
    session = sessions.get(session_id)
    event = message.get("event")
    if not session or is_subagent_session(session) or not isinstance(event, dict) or event.get("eventType") != "turn_end":
        return None
    data = event.get("data")
    if not isinstance(data, dict):
        return None
    assistant = data.get("message")
    if not isinstance(assistant, dict) or assistant.get("role") != "assistant":
        return None
    # Pi emits intermediate turn_end frames for tool-use loops. The final reply
    # is stop (legacy frames may omit stopReason), immediately before agent_end.
    stop_reason = assistant.get("stopReason")
    if stop_reason not in (None, "stop"):
        return None
    content = assistant.get("content")
    chunks: list[str] = []
    if isinstance(content, str):
        chunks.append(content)
    elif isinstance(content, list):
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text" and isinstance(block.get("text"), str):
                chunks.append(block["text"])
    text = sanitize_assistant_text("".join(chunks))
    if not text:
        return None
    seq = message.get("seq")
    final_id = f"{session_id}:{seq}" if isinstance(seq, int) and seq >= 0 else f"{session_id}:{int(time.time() * 1000)}"
    return {
        "id": safe_string(final_id, MAX_ID),
        "sessionId": session_id,
        "sessionName": session["name"],
        "text": text,
    }


def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload, separators=(",", ":")), flush=True)


def fetch_ticket(base_url: str, timeout: float) -> str:
    body = json.dumps({"scope": "browser"}).encode()
    request = Request(
        f"{base_url.rstrip('/')}/api/ws-ticket",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=timeout) as response:
        payload = json.load(response)
    ticket = payload.get("data", {}).get("ticket") if isinstance(payload, dict) else None
    if not payload.get("success") or not isinstance(ticket, str) or not ticket:
        raise RuntimeError("Pi Dashboard ticket request failed")
    return ticket


def find_session_identity(payload: Any, session_id: str) -> dict[str, Any] | None:
    """Return the authoritative REST session row without exposing it to QML."""
    rows = payload.get("data") if isinstance(payload, dict) else None
    if not isinstance(rows, list):
        return None
    return next(
        (
            row
            for row in rows
            if isinstance(row, dict) and safe_string(row.get("id"), MAX_ID) == session_id
        ),
        None,
    )


def fetch_session_identity(base_url: str, session_id: str, timeout: float) -> dict[str, Any] | None:
    with urlopen(f"{base_url.rstrip('/')}/api/sessions", timeout=timeout) as response:
        return find_session_identity(json.load(response), session_id)


def listen(base_url: str, timeout: float) -> int:
    sessions: dict[str, dict[str, Any]] = {}
    subscribed: set[str] = set()
    pending_by_session: dict[str, set[str]] = {}
    ws: websocket.WebSocket | None = None

    while True:
        try:
            ticket = fetch_ticket(base_url, timeout)
            ws = websocket.create_connection(
                f"{base_url.rstrip('/').replace('http://', 'ws://').replace('https://', 'wss://')}/ws?ticket={ticket}",
                timeout=timeout,
            )
            # Keep the control socket alive while waiting for an ask_user frame;
            # a quiet dashboard is normal, not a connection failure.
            ws.settimeout(max(timeout, 30.0))
            while True:
                raw = ws.recv()
                if raw is None:
                    raise RuntimeError("dashboard socket closed")
                try:
                    message = json.loads(raw)
                except (TypeError, json.JSONDecodeError):
                    continue
                if not isinstance(message, dict):
                    continue

                kind = message.get("type")
                if kind == "sessions_snapshot":
                    sessions = {}
                    for row in message.get("sessions", []):
                        clean = sanitize_session(row)
                        if clean:
                            sessions[clean["id"]] = clean
                    subscribed.clear()
                    pending_by_session.clear()
                    # Session names remain inside this helper until a real prompt arrives.
                    emit({"type": "sessions_snapshot", "sessions": []})
                    for session_id, session in sessions.items():
                        if session["watching"]:
                            ws.send(json.dumps({"type": "subscribe", "sessionId": session_id, "lastSeq": 0}))
                            subscribed.add(session_id)
                            emit({"type": "session_activity", "sessionId": session_id})
                elif kind == "session_added":
                    clean = sanitize_session(message.get("session"))
                    if clean:
                        sessions[clean["id"]] = clean
                        if clean["watching"]:
                            ws.send(json.dumps({"type": "subscribe", "sessionId": clean["id"], "lastSeq": 0}))
                            subscribed.add(clean["id"])
                elif kind == "session_updated":
                    session_id = safe_string(message.get("sessionId"), MAX_ID)
                    current = sessions.get(session_id)
                    updates = message.get("updates") if isinstance(message.get("updates"), dict) else {}
                    # Unknown sessions include subagents rejected at session_added;
                    # never reconstruct identity from a partial update.
                    if session_id and current and is_subagent_session(updates):
                        sessions.pop(session_id, None)
                        pending_by_session.pop(session_id, None)
                        if session_id in subscribed:
                            ws.send(json.dumps({"type": "unsubscribe", "sessionId": session_id}))
                            subscribed.discard(session_id)
                    elif session_id and current:
                        name = safe_name(updates.get("name")) if "name" in updates else current["name"]
                        status = updates.get("status") if "status" in updates else ("streaming" if current["watching"] else "active")
                        watching = is_watching_status(status)
                        became_active = watching and not current["watching"]
                        current = {"id": session_id, "name": name or "Pi session", "watching": watching}
                        sessions[session_id] = current
                        if became_active:
                            emit({"type": "session_activity", "sessionId": session_id})
                        if watching and session_id not in subscribed:
                            ws.send(json.dumps({"type": "subscribe", "sessionId": session_id, "lastSeq": 0}))
                            subscribed.add(session_id)
                        elif not watching and not pending_by_session.get(session_id) and session_id in subscribed:
                            ws.send(json.dumps({"type": "unsubscribe", "sessionId": session_id}))
                            subscribed.discard(session_id)
                elif kind == "session_removed":
                    session_id = safe_string(message.get("sessionId"), MAX_ID)
                    sessions.pop(session_id, None)
                    pending_by_session.pop(session_id, None)
                    subscribed.discard(session_id)
                    emit({"type": "session_removed", "sessionId": session_id})
                elif kind == "event":
                    clean = sanitize_final_event(message, sessions)
                    if clean:
                        # session_added can race the dashboard's subagent metadata
                        # enrichment. Recheck the authoritative REST row at the
                        # final-message boundary and fail closed if it is absent.
                        identity = fetch_session_identity(base_url, clean["sessionId"], timeout)
                        if identity and not is_subagent_session(identity):
                            emit({"type": "final_message", "message": clean})
                # event_replay is deliberately ignored: only completions observed
                # live after subscription should surface as new notifications.
                elif kind == "prompt_request":
                    clean = sanitize_prompt(message, sessions)
                    if clean:
                        pending_by_session.setdefault(clean["sessionId"], set()).add(clean["id"])
                        emit({"type": "prompt_request", "prompt": clean})
                elif kind in {"prompt_dismiss", "prompt_cancel"}:
                    prompt_id = safe_string(message.get("promptId"), MAX_ID)
                    session_id = safe_string(message.get("sessionId"), MAX_ID)
                    if prompt_id:
                        emit({"type": kind, "promptId": prompt_id})
                        pending_by_session.get(session_id, set()).discard(prompt_id)
                        if not pending_by_session.get(session_id):
                            pending_by_session.pop(session_id, None)
                            if session_id in subscribed and not sessions.get(session_id, {}).get("watching"):
                                ws.send(json.dumps({"type": "unsubscribe", "sessionId": session_id}))
                                subscribed.discard(session_id)
        except Exception as exc:
            if ws is not None:
                try:
                    ws.close()
                except Exception:
                    pass
                ws = None
            emit({"type": "status", "available": False, "error": safe_string(str(exc), 240) or "Pi Dashboard unavailable"})
            time.sleep(5)


def send_answer(args: argparse.Namespace) -> int:
    ticket = fetch_ticket(args.url, args.timeout)
    ws_url = f"{args.url.rstrip('/').replace('http://', 'ws://').replace('https://', 'wss://')}/ws?ticket={ticket}"
    ws = websocket.create_connection(ws_url, timeout=args.timeout)
    try:
        payload: dict[str, Any] = {
            "type": "prompt_response",
            "sessionId": safe_string(args.session_id, MAX_ID),
            "promptId": safe_string(args.prompt_id, MAX_ID),
            "cancelled": args.cancelled,
            "source": "quickshell-coding-agent-questions",
        }
        if not args.cancelled:
            payload["answer"] = args.answer
        ws.send(json.dumps(payload, separators=(",", ":")))
        # The server routes the frame immediately; keep the socket alive briefly
        # so the bridge can emit its prompt_dismiss broadcast to listeners.
        time.sleep(0.15)
    finally:
        ws.close()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("listen", "answer"))
    parser.add_argument("--url", default="http://100.64.1.150:8000")
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--session-id", default="")
    parser.add_argument("--prompt-id", default="")
    parser.add_argument("--answer", default="")
    parser.add_argument("--cancelled", action="store_true")
    args = parser.parse_args()
    if args.mode == "listen":
        return listen(args.url, args.timeout)
    if not args.session_id or not args.prompt_id:
        parser.error("answer requires --session-id and --prompt-id")
    return send_answer(args)


if __name__ == "__main__":
    raise SystemExit(main())
