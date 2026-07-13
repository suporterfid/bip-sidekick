# Family Calendar Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record and enforce the decision to keep Bip's family-calendar capability Google-MCP-only, read-only, and advisory-first while deferring Cal.diy.

**Architecture:** Documentation is the product surface for issue #14: an ADR records the decision, `docs/CALENDAR.md` defines the operator workflow and non-goals, and existing roadmap/security docs link to that contract. A standard-library Python validator checks the documents and the Compose OAuth/tool boundary so future edits cannot silently introduce a Cal.diy service or calendar write scope.

**Tech Stack:** Markdown, Docker Compose YAML, Python 3 standard library `unittest`, `subprocess`, and `pathlib`.

## Global Constraints

- Keep Google Calendar at `https://www.googleapis.com/auth/calendar.readonly`.
- Do not add a Cal.diy service, database, public port, OAuth client, or scheduler.
- Calendar responses remain advisory; Bip must not create, update, delete, RSVP to, or send invitations for events.
- Any future calendar write is a separate Stage 5 hand requiring a dedicated ADR, least-privilege credentials, manual Telegram approval, and audit correlation.
- The current `services/google-mcp` stub is a separate runtime-integration gap and must not be solved by widening scopes in this issue.

---

### Task 1: Add the failing architecture validation test

**Files:**
- Create: `scripts/test-calendar-architecture.py`

**Interfaces:**
- Consumes: `scripts/validate-calendar-architecture.py` executed with Python 3.
- Produces: a repeatable test that requires the validator to exit 0 and print `calendar architecture validation passed`.

- [ ] **Step 1: Write the failing test**

```python
from pathlib import Path
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate-calendar-architecture.py"


class CalendarArchitectureValidationTests(unittest.TestCase):
    def test_validator_accepts_the_documented_read_only_architecture(self):
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("calendar architecture validation passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails for the missing validator**

Run from the worktree with WSL Python:

```bash
python3 scripts/test-calendar-architecture.py
```

Expected: `FAIL` because `scripts/validate-calendar-architecture.py` does not exist yet.

- [ ] **Step 3: Commit the red test**

```bash
git add scripts/test-calendar-architecture.py
git commit -m "Test family calendar architecture guardrails"
```

### Task 2: Implement the focused architecture validator

**Files:**
- Create: `scripts/validate-calendar-architecture.py`

**Interfaces:**
- Consumes: repository files resolved relative to `Path(__file__).resolve().parents[1]`.
- Produces: exit code 0 plus `calendar architecture validation passed`, or exit code 1 plus one error per violated contract.

- [ ] **Step 1: Write the minimal validator**

```python
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]


def require_file(errors, relative_path, needles):
    path = ROOT / relative_path
    if not path.is_file():
        errors.append(f"missing {relative_path}")
        return
    text = path.read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            errors.append(f"{relative_path} must contain {needle!r}")


def main():
    errors = []
    require_file(
        errors,
        "docs/adr/ADR-005-family-calendar-architecture.md",
        ["Google Calendar", "calendar.readonly", "Cal.diy", "Stage 5"],
    )
    require_file(
        errors,
        "docs/CALENDAR.md",
        ["Read-only calendar workflow", "must not create", "manual Google Calendar action"],
    )

    compose = (ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    if "https://www.googleapis.com/auth/calendar.readonly" not in compose:
        errors.append("docker-compose.yml must retain calendar.readonly")
    if re.search(r"https://www\.googleapis\.com/auth/calendar(?!\.readonly)", compose):
        errors.append("docker-compose.yml must not grant a writable Calendar scope")
    if "cal.diy" in compose.lower():
        errors.append("docker-compose.yml must not attach Cal.diy")

    for relative_path in ("README.md", "docs/ROADMAP.md", "docs/SECURITY.md"):
        text = (ROOT / relative_path).read_text(encoding="utf-8")
        if "docs/CALENDAR.md" not in text:
            errors.append(f"{relative_path} must link docs/CALENDAR.md")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("calendar architecture validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Run the test and verify it still fails on missing documentation**

```bash
python3 scripts/test-calendar-architecture.py
```

Expected: `FAIL` with missing ADR/guide/link errors from the validator.

- [ ] **Step 3: Commit the validator**

```bash
git add scripts/validate-calendar-architecture.py
git commit -m "Add family calendar architecture validator"
```

### Task 3: Add the decision documents and links

**Files:**
- Create: `docs/adr/ADR-005-family-calendar-architecture.md`
- Create: `docs/CALENDAR.md`
- Modify: `README.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/SECURITY.md`

**Interfaces:**
- Consumes: the requirements in `docs/superpowers/specs/2026-07-10-family-calendar-architecture-design.md`.
- Produces: the operator-facing contract consumed by Hermes prompts, contributors, and the validator.

- [ ] **Step 1: Add ADR-005 with the selected decision**

Write `docs/adr/ADR-005-family-calendar-architecture.md` with these sections and decisions:

```markdown
# ADR-005: Google Calendar read-only for family scheduling

Status: Accepted

## Context

Bip already connects Hermes to the internal `google-mcp` service. Google OAuth is restricted to Gmail and Calendar read-only scopes, and the project is read-only first. Issue #14 asks whether family scheduling should remain on Google MCP or add a self-hosted Cal.diy layer.

## Decision

Keep Google Calendar as the only calendar integration for now. Bip may read events and produce summaries, conflict findings, buffers, and planning suggestions. It must not create, update, delete, RSVP to, or invite attendees to events.

Cal.diy is deferred. No Cal.diy service, database, public port, OAuth client, or scheduler belongs in the current Compose stack.

## Governance

Keep `https://www.googleapis.com/auth/calendar.readonly`. Any future calendar write is a separate Stage 5 hand with a dedicated ADR, least-privilege credentials, manual Telegram approval, and audit records for proposal, decision, execution, and outcome.

## Consequences

The current workflow is smaller and observable, but event creation remains a deliberate manual Google Calendar action. The placeholder `services/google-mcp` runtime remains a separate issue: it must be replaced by a verified read-only Calendar implementation before real account use.

## Revisit triggers

Re-open this decision only for a concrete shared-booking requirement, an unavoidable multi-calendar coordination gap, and an identified operator for Cal.diy persistence, authentication, backups, upgrades, and incident response.
```

- [ ] **Step 2: Add `docs/CALENDAR.md`**

Write this complete operator contract, including the explicit manual handoff and the link to ADR-005:

```markdown
# Family Calendar Contract

This is Bip's read-only calendar contract for the current Google MCP architecture. See [ADR-005](adr/ADR-005-family-calendar-architecture.md) for the decision and revisit criteria.

## Read-only calendar workflow

Bip may read today's and upcoming events through the internal Google MCP service and use them to:

- summarize the day and upcoming commitments;
- identify overlapping events, missing buffers, and likely travel conflicts;
- suggest planning priorities or candidate time windows; and
- include calendar context in the daily brief and vault note.

These are observations and proposals. Bip must tell the user when the read-only data is insufficient to answer an availability question.

## Non-goals

Bip must not create, update, delete, move, RSVP to, or invite attendees to calendar events. It must not send scheduling messages or click booking links. Calendar writes remain a deliberate manual Google Calendar action by the user.

The Compose stack must keep `https://www.googleapis.com/auth/calendar.readonly`, keep Google MCP on the internal network, and leave Cal.diy absent. The placeholder `services/google-mcp` runtime is a separate issue; it must be replaced with a verified read-only implementation before real-account use.

## Approval boundary

If a user asks Bip to change a calendar, Bip may describe the proposed change and ask the user to perform it manually. A future automated write must be a separate Stage 5 hand with least-privilege credentials, explicit manual Telegram approval, and audit records for proposal, decision, execution, and outcome.

## Revisit Cal.diy

Open a new decision issue before adding Cal.diy only when there is a concrete shared-booking or unavoidable multi-calendar coordination need, an identified operator, and a plan for persistence, authentication, backups, upgrades, and incident response.
```

- [ ] **Step 3: Link the contract from existing operator docs**

Apply these exact text changes:

```markdown
# README.md, Documentation Map
- `docs/CALENDAR.md` - family-calendar read-only workflow and Cal.diy decision.

# docs/ROADMAP.md, Stage 2 - Daily brief
- Read Google MCP with read-only scopes; follow [`docs/CALENDAR.md`](CALENDAR.md) for calendar behavior.

# docs/SECURITY.md, Runtime Boundaries
Calendar behavior is advisory-only and follows [`docs/CALENDAR.md`](CALENDAR.md); calendar writes remain outside Stages 1-4.
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
python3 scripts/test-calendar-architecture.py
```

Expected: `OK` and `calendar architecture validation passed`.

- [ ] **Step 5: Commit the documents and links**

```bash
git add docs/adr/ADR-005-family-calendar-architecture.md docs/CALENDAR.md README.md docs/ROADMAP.md docs/SECURITY.md
git commit -m "Document Google Calendar read-only architecture"
```

### Task 4: Verify, update issue #14, and prepare publication

**Files:**
- Modify: GitHub issue `suporterfid/bip-sidekick#14` with validation evidence.

**Interfaces:**
- Consumes: commits from Tasks 1-3 and repository validation commands.
- Produces: a closed-loop issue note ready for PR review and merge.

- [ ] **Step 1: Run focused and repository validations**

```bash
python3 scripts/test-calendar-architecture.py
bash scripts/validate-hermes-migration.sh
docker compose --profile core --profile openwa config
git diff --check HEAD~3..HEAD
```

Expected: the focused test reports `OK`, the Hermes validator exits 0, Compose renders with the existing read-only scopes, and `git diff --check` reports no whitespace errors. If the Windows/WSL worktree Git-path mismatch recurs, record it as an environment limitation and run the content validators from a WSL-native checkout.

- [ ] **Step 2: Add the validation comment to issue #14**

Record the commits, exact commands, and any environment-only limitation. Keep the issue open until the PR is merged.

- [ ] **Step 3: Publish and merge the PR**

Use the GitHub publish workflow to push `codex/calendar-architecture`, open a PR that closes #14, wait for checks, and merge it. After merge, close #14 with the merge SHA and final validation evidence.
```

## Self-review checklist

- Spec coverage: the decision, requirements, alternatives, readiness gap, acceptance mapping, and revisit triggers are covered by Tasks 2-4.
- Placeholder scan: no unresolved placeholder or missing-step language is present; Cal.diy deferral is an explicit product decision.
- Type/contract consistency: the test expects the exact validator output, and the validator checks the exact paths and scope strings created or linked in Task 3.
