#!/usr/bin/env python3
"""Validate the advisory-only Gmail bill-reminder contract."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {
    "docs/BILL_REMINDERS.md": [
        "advisory-only design",
        "Gmail read-only access",
        "Recognition Signals",
        "Reminder Fact Shape",
        "Deduplication",
        "confidence=<high|medium|low>",
        "must not click payment links",
        "Stage 5 hand",
        "/audit/actions.jsonl",
    ],
    "services/hermes/templates/cron/daily-brief.md": [
        "bill-related Gmail",
        "upcoming and overdue bills",
        "Do not click payment links, pay bills",
        "source message",
    ],
    "services/hermes/templates/BIP.md": [
        "Scan Gmail for bill, invoice, due-date, payment confirmation, and overdue signals",
        "Deduplicate bill reminders by vendor, account hint, amount, and due date or billing period",
        "Never pay bills",
    ],
    "vault/BIP.md": [
        "Scan Gmail for bill, invoice, due-date, payment confirmation, and overdue signals",
        "Deduplicate bill reminders by vendor, account hint, amount, and due date or billing period",
        "Never pay bills",
    ],
    "docs/SECURITY.md": [
        "Bill reminders are advisory-only",
        "docs/BILL_REMINDERS.md",
    ],
    "docs/ROADMAP.md": [
        "Gmail bill reminders",
        "advisory-only",
    ],
    "README.md": [
        "docs/BILL_REMINDERS.md",
    ],
}


def main() -> int:
    errors: list[str] = []
    for relative, needles in REQUIRED.items():
        text = (ROOT / relative).read_text(encoding="utf-8")
        for needle in needles:
            if needle not in text:
                errors.append(f"{relative} must contain {needle!r}")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
