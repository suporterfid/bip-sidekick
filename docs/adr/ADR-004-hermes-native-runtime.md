# ADR-004 - Hermes-native runtime

## Status

Accepted

## Context

The original reference architecture split the runtime across custom stubs:
`agent`, `telegram-bridge`, and `brief-engine`. Hermes now provides the gateway, cron,
Telegram integration, session runtime, MCP integration, and dangerous-command approvals
that those stubs were meant to grow into.

The repo still needs a small amount of Bip-specific structure around Hermes: a portable
Markdown vault, a provider-neutral identity file, internal read-only MCP senses, a
container-scoped shell boundary, and an audit mirror that can prove approval decisions
before real hands are attached.

## Decision

Use Hermes as Bip's native runtime. Keep Bip's differentiators outside Hermes core:
`/vault` as shared memory, `vault/BIP.md` as identity, read-only MCP senses, manual
approval policy, and explicit audit posture.

The active Compose runtime is:

- `hermes` in the `core` profile for Telegram, cron, MCP client sessions, approval prompts,
  shell context, and generated `SOUL.md`.
- `vault-sync` in the `core` profile for syncing the Markdown vault to a private git remote.
- `google-mcp` in the `core` profile for Gmail and Calendar read-only senses.
- `openwa` in the `openwa` profile for optional WhatsApp read-only triage.

`agent`, `telegram-bridge`, and `brief-engine` are superseded runtime stubs. They are not
the primary command, approval, or scheduling path.

The runtime must preserve these boundaries:

- No Docker socket mount and no broad host filesystem mount into Hermes.
- No published Hermes dashboard/API port by default.
- Google and OpenWA remain read-only during Stages 1-4.
- Cron briefs can write the daily note and deliver the brief to Telegram, but cannot send,
  deploy, spend, delete, or mutate external systems.
- Stage 5 hands are separate issues and must be least-privilege, manually approved, and
  audit-correlated before they are attached.

## Consequences

- Fewer custom services to maintain.
- Deployment remains Docker Compose based.
- Stage 5 hands remain deferred until each hand is approval-gated and auditable.
- Hermes logs are not automatically the full Bip JSONL audit contract; that mirror is
  tracked separately.
- Docs, Makefile targets, and validation scripts should describe Hermes as the current
  runtime instead of the old custom HTTP `/run` shim.

## Validation

Use the repository checks as the decision guard:

```bash
bash scripts/validate-hermes-migration.sh
sh scripts/validate-hermes-shell-scope.sh
docker compose --profile core --profile openwa config
```
