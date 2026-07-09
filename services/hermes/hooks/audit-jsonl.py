#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime, timezone


AUDIT_PATH = os.environ.get("BIP_AUDIT_LOG", "/audit/actions.jsonl")
MAX_VALUE_CHARS = 2000


def utc_now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def compact(value):
    if value is None or isinstance(value, (bool, int, float)):
        return value
    if isinstance(value, str):
        return value if len(value) <= MAX_VALUE_CHARS else value[:MAX_VALUE_CHARS] + "...[truncated]"
    if isinstance(value, list):
        return [compact(item) for item in value[:50]]
    if isinstance(value, dict):
        return {str(key): compact(item) for key, item in list(value.items())[:80]}
    return str(value)


def load_payload():
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        return {"hook_event_name": "invalid", "extra": {"raw": raw, "error": str(exc)}}
    return data if isinstance(data, dict) else {"hook_event_name": "invalid", "extra": {"raw": data}}


def event_type(hook_event):
    if hook_event == "pre_approval_request":
        return "proposal"
    if hook_event == "post_approval_response":
        return "decision"
    if hook_event == "post_tool_call":
        return "execution"
    return "observation"


def outcome_for(hook_event, extra):
    if hook_event == "post_approval_response":
        choice = str(extra.get("choice") or "")
        if choice in {"once", "session", "always"}:
            return "approved"
        if choice in {"deny", "timeout"}:
            return choice
        return choice or None
    if hook_event == "post_tool_call":
        return "executed"
    return None


def build_record(payload):
    extra = payload.get("extra") if isinstance(payload.get("extra"), dict) else {}
    tool_input = payload.get("tool_input") if isinstance(payload.get("tool_input"), dict) else {}
    hook_event = str(payload.get("hook_event_name") or "")
    record = {
        "schema": "bip.audit.v1",
        "ts": utc_now(),
        "event": event_type(hook_event),
        "hook_event": hook_event,
        "session_id": payload.get("session_id") or "",
        "task_id": extra.get("task_id"),
        "tool_call_id": extra.get("tool_call_id"),
        "surface": extra.get("surface"),
        "actor": {
            "kind": "hermes",
            "cwd": payload.get("cwd") or "",
        },
        "action": {
            "tool_name": payload.get("tool_name"),
            "command": extra.get("command") or tool_input.get("command"),
            "description": extra.get("description"),
            "pattern_key": extra.get("pattern_key"),
            "pattern_keys": extra.get("pattern_keys"),
            "input": compact(tool_input) if tool_input else None,
        },
        "decision": {
            "choice": extra.get("choice"),
            "outcome": outcome_for(hook_event, extra),
            "session_key": extra.get("session_key"),
        },
        "execution": {
            "duration_ms": extra.get("duration_ms"),
            "result": compact(extra.get("result")),
        },
        "telegram": {
            "approval_message_id": None,
            "approval_chat_id": None,
        },
        "unsupported_fields": [],
    }
    if hook_event in {"pre_approval_request", "post_approval_response"}:
        record["unsupported_fields"].extend([
            "telegram.approval_message_id",
            "telegram.approval_chat_id",
        ])
    return record


def append_record(record):
    os.makedirs(os.path.dirname(AUDIT_PATH), exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_APPEND
    fd = os.open(AUDIT_PATH, flags, 0o600)
    with os.fdopen(fd, "a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")))
        handle.write("\n")


def main():
    append_record(build_record(load_payload()))


if __name__ == "__main__":
    main()
