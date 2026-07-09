# ADR-003: Borrow Harness governance pattern, not the Harness platform

**Status:** Accepted
**Date:** 2026-07-09

## Context
We want production-grade guardrails (sandboxing, scoped creds, audit) for an agent that
can eventually send/deploy. Harness.io offers this at enterprise scale, but adopting it
is a large, costly platform migration for a solo operator on GitHub Actions + Dokploy.

## Decision
Implement the *pattern* — read-only default, scoped keys per tool, human tap for acts,
append-only audit — as lightweight logic in `telegram-bridge`, without adopting Harness.

## Consequences
- (+) Strong guardrails at near-zero cost/complexity.
- (+) No platform migration; keeps existing CI/CD.
- (−) We maintain the gate ourselves (it's small). Revisit if the stack grows to a team.
