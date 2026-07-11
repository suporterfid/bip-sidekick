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
