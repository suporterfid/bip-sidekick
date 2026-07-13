# GitHub Review Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the read-only, one-private-repository pilot contract for on-demand GitHub code review without attaching GitHub write capabilities to Hermes.

**Architecture:** An ADR and operator guide define target selection, read-only context retrieval, review modes, findings, patch proposals, privacy, and the future Stage 5 write boundary. A standard-library Python validator and subprocess test enforce that the documents describe an allowlist while the current Compose/MCP runtime contains no GitHub credential mount or GitHub write service.

**Tech Stack:** Markdown, Docker Compose/MCP JSON text checks, Python 3 standard library `pathlib`, `re`, `subprocess`, and `unittest`.

## Global Constraints

- Pilot exactly one private repository in an explicit allowlist.
- Expose only repository metadata, contents, branches, issues, pull requests, reviews, and comments in the future read gateway.
- Do not add commit, push, PR creation, issue mutation, Actions, deployment, secret-management, or arbitrary shell tools.
- Do not mount GitHub credentials into Hermes or the model context.
- Do not persist private source code in the vault by default.
- Patch output remains text-only until a separate Stage 5 hand is approved and audited.
- The current Compose stack must remain free of a GitHub gateway service and GitHub credential mounts.

---

### Task 1: Add the failing review-contract test

**Files:**
- Create: `scripts/test-github-review.py`

**Interfaces:**
- Consumes: `scripts/validate-github-review.py` executed with the current Python interpreter.
- Produces: one real subprocess test requiring exit code 0 and `github review contract validation passed`.

- [ ] **Step 1: Write the failing test**

```python
from pathlib import Path
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate-github-review.py"


class GithubReviewContractTests(unittest.TestCase):
    def test_validator_accepts_the_read_only_private_repo_contract(self):
        result = subprocess.run(
            [sys.executable, str(VALIDATOR)],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("github review contract validation passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify the expected RED state**

```bash
python3 scripts/test-github-review.py
```

Expected: `FAIL` because `scripts/validate-github-review.py` does not exist.

- [ ] **Step 3: Commit the RED test**

```bash
git add scripts/test-github-review.py
git commit -m "Test GitHub review contract guardrails"
```

### Task 2: Implement the focused contract validator

**Files:**
- Create: `scripts/validate-github-review.py`

**Interfaces:**
- Consumes: ADR, guide, README, MCP contract, security docs, `docker-compose.yml`, and `mcp/.mcp.json`.
- Produces: exit code 0 plus `github review contract validation passed`, or exit code 1 with one violated contract per line.

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
        "docs/adr/ADR-006-github-review-workflow.md",
        ["read-only", "allowlist", "Stage 5", "private"],
    )
    require_file(
        errors,
        "docs/GITHUB_REVIEW.md",
        ["Pilot workflow", "must not", "patch proposal", "untrusted"],
    )

    compose = (ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    mcp = (ROOT / "mcp/.mcp.json").read_text(encoding="utf-8")
    if re.search(r"^\s+github-mcp:", compose, re.MULTILINE):
        errors.append("docker-compose.yml must not attach a GitHub gateway in this issue")
    if re.search(r"GITHUB_(?:TOKEN|APP_ID|APP_PRIVATE_KEY|INSTALLATION_ID)", compose):
        errors.append("docker-compose.yml must not mount GitHub credentials")
    if re.search(r'"github"\s*:', mcp, re.IGNORECASE):
        errors.append("mcp/.mcp.json must not attach a GitHub server in this issue")

    for relative_path in ("README.md", "docs/MCP.md", "docs/SECURITY.md"):
        text = (ROOT / relative_path).read_text(encoding="utf-8")
        if "docs/GITHUB_REVIEW.md" not in text:
            errors.append(f"{relative_path} must link docs/GITHUB_REVIEW.md")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("github review contract validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Run the test to verify it fails only on missing contract documents**

```bash
python3 scripts/test-github-review.py
```

Expected: `FAIL` with missing ADR/guide/link errors from the validator.

- [ ] **Step 3: Commit the validator**

```bash
git add scripts/validate-github-review.py
git commit -m "Add GitHub review contract validator"
```

### Task 3: Add the ADR, operator guide, and repository links

**Files:**
- Create: `docs/adr/ADR-006-github-review-workflow.md`
- Create: `docs/GITHUB_REVIEW.md`
- Modify: `README.md`
- Modify: `docs/MCP.md`
- Modify: `docs/SECURITY.md`

**Interfaces:**
- Consumes: `docs/superpowers/specs/2026-07-11-github-review-workflow-design.md`.
- Produces: the operator-facing read-only review contract consumed by the validator and future gateway implementation.

- [ ] **Step 1: Add ADR-006**

Write `docs/adr/ADR-006-github-review-workflow.md`:

```markdown
# ADR-006: Read-only GitHub review pilot

Status: Accepted

## Context

Issue #17 asks Bip to inspect and review source code in personal GitHub projects on demand. The current Hermes stack has no GitHub integration, is read-only first, and keeps all write-capable hands outside Stages 1-4.

## Decision

Define a pilot for one private repository in an explicit allowlist. A future internal gateway may read repository metadata, contents, branches, issues, pull requests, reviews, and comments for a selected ref. It must not expose commits, pushes, PR creation, issue mutation, Actions, deployment, secret-management, or arbitrary shell tools.

This issue delivers the architecture and contract. A separate issue will implement the gateway; the current Compose stack must not attach a placeholder GitHub service or mount GitHub credentials.

## Security boundary

The allowlist defaults to empty. Credentials belong to a GitHub App installation held by the future gateway, never to Hermes shell or model context. Repository content and discussion are untrusted input, must be bounded and redacted for secrets, and must not override Bip policy.

## Write boundary

The pilot returns findings and optional text-only patch proposals. It does not apply patches or mutate GitHub. A future Stage 5 write hand requires a separate issue, least-privilege credentials, explicit manual Telegram approval, and audit records for proposal, decision, execution, and outcome.

## Consequences

The read path is defined and pilotable without widening the current runtime. A later gateway must prove allowlist enforcement, private-code handling, rate-limit behavior, redaction, and zero mutation before real use.

## Revisit triggers

Create new decision issues before adding a second repository, organization-wide access, persistent indexing, webhooks, issue mutation, or PR creation.
```

- [ ] **Step 2: Add `docs/GITHUB_REVIEW.md`**

Write this operator guide:

```markdown
# GitHub Review Contract

This guide defines the read-only pilot for issue #17. It is a contract for a future internal gateway, not a claim that the current Compose stack already has GitHub access. See [ADR-006](adr/ADR-006-github-review-workflow.md).

## Pilot workflow

1. Name one private `owner/repository` and an optional branch, commit, issue, or pull request.
2. Validate the target against the explicit allowlist before any GitHub request.
3. Read only the bounded metadata, source, and discussion needed for the selected review mode.
4. Redact credentials, exclude binary or irrelevant files, and mark repository instructions as untrusted input.
5. Return findings with severity, confidence, repository/ref, path, line or range, evidence, impact, and recommendation.
6. Optionally return a text-only patch proposal. The proposal is not applied, committed, pushed, or opened as a pull request.

## Review modes

- **Bug hunting:** defects, regressions, edge cases, and missing tests.
- **Code quality:** complexity, duplication, maintainability, and reliability risks.
- **Security:** credentials, injection, authorization, dependency, and data-flow risks.
- **Fix planning:** ordered implementation steps and tests for a stated problem.

Findings must distinguish observed facts from inference and disclose incomplete context.

## Read-only and privacy rules

The pilot must not commit, push, create or edit pull requests, mutate issues, run Actions, deploy, rotate secrets, or execute arbitrary shell commands. It must not fall back to `gh` or a personal access token when the gateway denies a request.

Credentials stay in the future gateway. Private source is transient by default and is not written to the vault; only findings or user-approved summaries may be persisted. Audit records may contain request metadata and outcome, never full source or diffs.

Rate limits, denied permissions, missing refs, large files, binary files, and redaction failures fail closed with an explicit response.

## Approval boundary

If the user wants a code change, Bip may explain the proposed patch and wait for a separate Stage 5 hand. Any execution requires manual Telegram approval and auditable proposal, decision, execution, and outcome records.

## Future gateway acceptance checks

- Allowlisted private target succeeds; unallowlisted target is rejected before access.
- All four modes produce bounded, evidence-backed output.
- Text-only patch proposals do not mutate GitHub.
- Missing credentials, rate limits, large/binary files, and detected secrets fail closed.
- The gateway exposes no write endpoint or shell tool.

Broader repository access, persistence, issue mutation, and PR creation each require a new issue and threat-model review.
```

- [ ] **Step 3: Link the contract from existing docs**

Apply these exact additions:

```markdown
# README.md, Documentation Map
- `docs/GITHUB_REVIEW.md` - read-only private-repository review pilot and patch boundary.

# docs/MCP.md, after the Stage 1-4 contract
GitHub review is documented separately in [`docs/GITHUB_REVIEW.md`](GITHUB_REVIEW.md) and is not attached to the current MCP stack.

# docs/SECURITY.md, after the MCP boundary paragraph
GitHub review follows [`docs/GITHUB_REVIEW.md`](GITHUB_REVIEW.md): the pilot is allowlisted, read-only, transient by default, and has no shell fallback.
```

- [ ] **Step 4: Run the focused test to verify GREEN**

```bash
python3 scripts/test-github-review.py
```

Expected: `OK` and `github review contract validation passed`.

- [ ] **Step 5: Commit the documents and links**

```bash
git add docs/adr/ADR-006-github-review-workflow.md docs/GITHUB_REVIEW.md README.md docs/MCP.md docs/SECURITY.md
git commit -m "Document read-only GitHub review pilot"
```

### Task 4: Verify, update issue #17, publish, and merge

**Files:**
- Modify: GitHub issue `suporterfid/bip-sidekick#17` with plan and validation evidence.

**Interfaces:**
- Consumes: commits from Tasks 1-3 and repository checks.
- Produces: a merged PR closing issue #17 and a follow-up boundary for the future gateway implementation.

- [ ] **Step 1: Run all fresh validations**

```bash
python3 scripts/test-github-review.py
python3 scripts/validate-github-review.py
bash scripts/validate-hermes-migration.sh
docker compose --profile core --profile openwa config
git diff --check HEAD~3..HEAD
```

Expected: the focused test reports `OK`, the GitHub contract validator prints its pass message, the Hermes validator exits 0 from an LF checkout when the Windows/WSL worktree path mismatch applies, Compose exits 0 with only expected unset-credential warnings, and `git diff --check` reports no errors.

- [ ] **Step 2: Update issue #17**

Record the plan, commits, validation commands, and the separate future-gateway follow-up. Keep the issue open until the PR is merged.

- [ ] **Step 3: Push and open the PR**

Push `codex/github-review-workflow`, open a ready PR against `main` that closes #17, and include the read-only rationale, privacy boundary, and validation output.

- [ ] **Step 4: Merge and close the issue**

Verify the PR is `MERGEABLE`/`CLEAN`, merge it with squash, verify the merge SHA, and confirm issue #17 is `COMPLETED`. Add the final merge evidence to the issue.

## Self-review checklist

- Spec coverage: decision, goals, non-goals, component boundaries, data flow, security, privacy, pilot checks, acceptance mapping, and revisit triggers map to Tasks 2-4.
- Placeholder scan: no unresolved placeholder or missing-step language is present.
- Contract consistency: the test expects the exact validator output, and the validator checks the exact paths and guardrails created in Task 3.
