# ADR-004 - Hermes-native runtime

## Status

Accepted

## Context

The original reference architecture split the runtime across custom stubs:
`agent`, `telegram-bridge`, and `brief-engine`. Hermes now provides the gateway, cron,
Telegram integration, session runtime, MCP integration, and dangerous-command approvals
that those stubs were meant to grow into.

## Decision

Use Hermes as Bip's native runtime. Keep Bip's differentiators outside Hermes core:
`/vault` as shared memory, `vault/BIP.md` as identity, read-only MCP senses, manual
approval policy, and explicit audit posture.

## Consequences

- Fewer custom services to maintain.
- Deployment remains Docker Compose based.
- Stage 5 hands remain deferred until each hand is approval-gated and auditable.
- Hermes logs are not automatically the full Bip JSONL audit contract; that mirror is
  tracked separately.
