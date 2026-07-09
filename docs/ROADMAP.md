# Roadmap - Hermes-native staged build order

Each stage ships and stops on its own. Do not attach mutation tools until the approval and
audit posture is proven.

## Stage 1 - Hermes core runtime

- Build `services/hermes/`.
- Run Hermes through `make up-core`.
- Enforce Telegram allowlist.
- Mount `/vault`, `/audit`, and `hermes_home`.

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
- Define or implement the `/audit/actions.jsonl` mirror.

**DoD:** a dangerous interactive action blocks for approval, cron cannot act, and the audit
posture is documented.

## Stage 4 - OpenWA read-only triage

- Start `make up-openwa`.
- Confirm `MCP_READONLY=true`.
- Fold recent WhatsApp context into the daily brief.

**DoD:** WhatsApp context can influence the brief, but no WhatsApp sends are available.

## Stage 5 - Gated hands

- Add each send/deploy/spend tool as its own issue.
- Grant least-privilege credentials.
- Require manual Telegram approval.
- Mirror proposal, decision, execution, and outcome to audit.

**DoD:** a hand executes only after explicit approval and has enough audit detail to
reconstruct the decision.

## System Definition Of Done

You wake up and see one prioritized action drawn from your real calendar, inbox, backlog,
and optional WhatsApp context. Nothing changes the world without your tap.
