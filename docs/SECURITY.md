# Security & Governance

Bip is read-only first. Hermes may reason, draft, summarize, and propose. Anything that
changes the world is a gated exception.

## Rules

1. **Read-only senses.** Google MCP uses Gmail and Calendar read-only scopes. OpenWA runs
   with `MCP_READONLY=true`.
2. **Telegram allowlist.** Only `TELEGRAM_ALLOWED_USERS` can interact with the bot.
3. **Manual approvals.** Dangerous interactive tools use Hermes manual approval mode.
4. **Cron cannot act.** Scheduled briefs run with cron action behavior denied.
5. **Audit before hands.** Real sends/deploys/spend stay disabled until
   `/audit/actions.jsonl` can record proposal, approval, denial, execution, and outcome.
   See `docs/AUDIT.md` for the Hermes hook mirror and current unsupported fields.

## Runtime Boundaries

Hermes is the only active agent runtime. The historical `agent`, `telegram-bridge`, and
`brief-engine` service directories remain as migration context, but the current stack does
not use them for commands, approvals, or scheduled briefs.

MCP servers are senses during Stages 1-4. They are reachable only on the Docker internal
network, Google OAuth scopes are read-only, OpenWA is read-only, and Hermes tool filters
exclude send, create, update, delete, reply, deploy, and spend-style operations. See
`docs/MCP.md` for the read-only MCP contract.

## Shell Posture

Shell is allowed inside the Hermes container because Bip needs operational flexibility.
The default deployment keeps the blast radius bounded; see `docs/SHELL.md` for the
container-scoped shell contract and validation target.

- No Docker socket mount.
- No broad host filesystem bind mount.
- No host SSH key mount.
- No published Hermes port by default.
- `/vault`, `/audit`, and `hermes_home` are the intended writable surfaces.

Host-level deployment actions belong in Stage 5 as explicit hands with least-privilege
credentials, manual approval, and audit.

## Audit Caveats

`/audit/actions.jsonl` is the governance mirror, not a replacement for proving each future
hand end to end. `unsupported_fields` in the audit record identifies correlation data that
Hermes did not expose to a hook payload. Do not attach a Stage 5 hand until the approval
request, approver decision, execution result, and outcome can be reconstructed.

## Credentials

- Secrets live in `.env` or Docker secrets, never in the repo.
- `GOOGLE_REFRESH_TOKEN` and `openwa_session` are sensitive and should be encrypted in
  backups.
- Widening Google scopes requires an ADR.
- WhatsApp automation can trigger account risk; use a spare number.

## Before Real Accounts

- [ ] `.env` is gitignored and contains no committed secrets.
- [ ] Google scopes are read-only.
- [ ] Telegram allowlist is tested.
- [ ] Hermes manual approvals are verified.
- [ ] Cron deny behavior is verified.
- [ ] `/audit/actions.jsonl` posture is known.
- [ ] `unsupported_fields` is acceptable for the intended hand, or the hand remains
      disabled.
- [ ] OpenWA uses a spare number and `MCP_READONLY=true`.
- [ ] Vault git repo is private.
