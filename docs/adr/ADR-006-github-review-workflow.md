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
