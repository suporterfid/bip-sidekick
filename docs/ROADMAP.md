# Roadmap - Hermes-native staged build order

Each stage ships and stops on its own. Do not attach mutation tools until the approval and
audit posture is proven.

The current repository shape is Hermes-native: `make up-core` starts Hermes, vault sync,
and Google MCP; `make up-gate` refreshes Hermes for approval/audit checks; `make up-openwa`
adds optional WhatsApp read-only triage. The roadmap below is still staged because each
surface must be verified before real accounts or write-capable hands are attached.

## Stage 1 - Hermes core runtime

- Build `services/hermes/`.
- Run Hermes through `make up-core`.
- Enforce Telegram allowlist.
- Mount `/vault`, `/audit`, and `hermes_home`.
- Keep the old `agent`, `telegram-bridge`, and `brief-engine` runtime paths inactive.

**DoD:** Hermes starts from Docker Compose, reads `vault/BIP.md`, generates runtime
`SOUL.md`, and responds through the allowed Telegram user.

## Stage 2 - Daily brief

- Configure Hermes cron from `BRIEF_CRON` and `TZ`.
- Read Google MCP with read-only scopes.
- Read `STATUS.md`, `BACKLOG.md`, and recent daily notes.
- Write `vault/daily/YYYY-MM-DD.md`.
- Send the same brief to Telegram.

**DoD:** one useful brief lands in the vault and Telegram, with exactly one next action.

## Stage 3 - Approvals and audit posture

- Confirm `approvals.mode: manual`.
- Confirm `approvals.cron_mode: deny`.
- Confirm dangerous interactive shell actions require approval where Hermes supports it.
- Keep shell container-scoped as documented in `docs/SHELL.md`.
- Keep the `/audit/actions.jsonl` hook mirror active and document unsupported fields.

**DoD:** a dangerous interactive action blocks for approval, cron cannot act, and the audit
posture is documented.

## Stage 4 - OpenWA read-only triage

- Start `make up-openwa`.
- Confirm `MCP_READONLY=true`.
- Fold recent WhatsApp context into the daily brief.

**DoD:** WhatsApp context can influence the brief, but no WhatsApp sends are available.

## Stage 4a - Gmail bill reminders

- Read Gmail bill, invoice, due-date, confirmation, and overdue signals.
- Keep reminders advisory-only and deduplicated.
- Surface upcoming and overdue items in the daily brief without paying or mutating accounts.

**DoD:** bill reminders can inform the brief, but payment and account changes remain absent.

## Stage 5 - Gated hands

- Add each send/deploy/spend tool as its own issue.
- Grant least-privilege credentials.
- Require manual Telegram approval.
- Mirror proposal, decision, execution, and outcome to audit.
- Do not attach a hand if approval or audit correlation cannot be proven.

**DoD:** a hand executes only after explicit approval and has enough audit detail to
reconstruct the decision.

## Validation Commands

Run these before claiming the staged architecture is still intact:

```bash
bash scripts/validate-hermes-migration.sh
sh scripts/validate-hermes-shell-scope.sh
docker compose --profile core --profile openwa config
```

## System Definition Of Done

You wake up and see one prioritized action drawn from your real calendar, inbox, backlog,
and optional WhatsApp context. Nothing changes the world without your tap.
