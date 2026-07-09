# Repository Guidelines

## Project Structure & Module Organization

`bip-sidekick` is a Docker Compose reference architecture. Core runtime code lives in
`services/hermes/`; read-only integrations live in `services/google-mcp/` and
`services/openwa/`. Historical stubs in `services/agent/`, `services/telegram-bridge/`, and
`services/brief-engine/` are superseded by Hermes. Docs live in `docs/`, including
`ARCHITECTURE.md`, `ROADMAP.md`, `SECURITY.md`, and `docs/adr/`. Working state lives in
`vault/` (`BIP.md`, `STATUS.md`, `BACKLOG.md`, `daily/`).

## Issue-First Workflow

Every request should map to a GitHub issue before implementation starts. First, look for an
existing related issue. If none exists, create one using the `Backlog item` workflow in
`docs/GITHUB_BACKLOG.md`, then start the work. Keep the issue updated with the plan,
decisions, and validation notes. When done, link the PR or commit, summarize the outcome,
and close the issue.

## Build, Test, and Development Commands

- `make up-core` builds and starts the Stage 1-2 stack: `vault-sync`, `google-mcp`, and `hermes`.
- `make up-gate` refreshes Hermes so you can verify manual approvals and cron deny behavior.
- `make up-openwa` starts optional WhatsApp read-only triage.
- `make logs SVC=hermes` tails runtime logs; swap `hermes` for `openwa` or another service.
- `make audit` tails `/audit/actions.jsonl` inside the Hermes container.
- `docker compose --profile core --profile openwa config` is a config sanity check.
- `sh scripts/validate-hermes-migration.sh` verifies key governance assumptions in the repo.

## Coding Style & Naming Conventions

Follow the existing style in each file. Shell scripts use POSIX `sh`, lowercase kebab-case
filenames, and simple guard-first logic (`set -eu`). Keep YAML and Markdown compact and
explicit; prefer descriptive names such as `TELEGRAM_ALLOWED_USERS`, `BRIEF_CRON`, and
`MCP_READONLY`. Document operator-facing behavior changes in `docs/`.

## Testing Guidelines

This repo relies more on configuration validation than on a large automated test suite.
Before opening a PR, run `docker compose ... config`,
`sh scripts/validate-hermes-migration.sh`, and exercise the affected `make` target. If you
add logic-heavy scripts or services, add a focused validation script near that surface.

## Commit & Pull Request Guidelines

Recent commits use short, imperative subjects such as `Migrate runtime to Hermes-native governance`.
Keep commits narrowly scoped. PRs should link the governing GitHub issue, explain the
operational impact, note any `.env` or credential changes, and include log
snippets or screenshots when the change affects Telegram, cron, or approvals. Close the
issue only after the result and validation are recorded.

## Security & Configuration Tips

Never widen the read-only posture casually. Review `docs/SECURITY.md` before changing OAuth
scopes, enabling new tools, publishing ports, or attaching any send/deploy capability.
