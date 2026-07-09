# ADR-003 - Borrow governance pattern, not a governance platform

**Status:** Accepted
**Date:** 2026-07-09
**Superseded-by:** ADR-004 for the concrete runtime implementation

## Context

We want production-grade guardrails such as sandboxing, scoped credentials, approvals, and
audit for an agent that can eventually send or deploy. Enterprise governance platforms are
too large for this solo Docker Compose deployment.

## Decision

Use the pattern: read-only default, scoped keys per tool, human approval for actions, and
append-only audit. The first implementation expected a small custom bridge. ADR-004 moves
the concrete runtime to Hermes while preserving the same governance intent.

## Consequences

- The project keeps a lightweight governance model.
- Runtime implementation can change as long as the read-only, approval, and audit contract
  remains intact.
- Real hands still require explicit approval and audit before they are attached.
