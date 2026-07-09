# Roadmap — staged build order

Each stage **ships and stops on its own** with a Definition of Done (DoD). Do not start
the next stage until the current DoD is met. Resist adding boxes not listed here (see
Non-Goals in the README).

---

## Stage 1 — Telegram → agent bridge
Single command inbox from your phone to the agent on the VPS.

- Bring up `telegram-bridge` + `agent` (`make up-core` starts the whole core; you can
  validate this piece first).
- Chat allowlist enforced.

**DoD:** you send a message in Telegram and the agent runs it on the VPS and replies.
A message from any other account is ignored.

_Est: ~½ day._

---

## Stage 2 — Daily Brief Engine  ← the real win
Reads Calendar + Gmail (read-only) + `BACKLOG.md`, returns the **one** next action with
reasoning, writes it to today's Obsidian daily note, and pushes it to Telegram.

- `google-mcp` up with read-only scopes.
- `brief-engine` cron wired to the brief prompt.

**DoD:** one correct brief lands in `vault/daily/YYYY-MM-DD.md` **and** in Telegram,
drawn from your real calendar/inbox/backlog.

> **Stop here for a week and just use it.** This is where most of the value lives.

_Est: ~1 day._

---

## Stage 3 — Approval + audit gate
Any "act" tool requires a Telegram reply; every action appends to the audit log.

- `GATE_MODE=strict`.
- Audit sink writing `actions.jsonl`.

**DoD:** one blocked action (waits for your tap) and one approved action, both logged
with the approving message id.

_Est: ~1 day._

---

## Stage 4 — OpenWA read-only triage
WhatsApp messages summarized into the daily brief.

- `make up-openwa`, scan the QR with a **spare** number.
- `MCP_READONLY=true` confirmed; `ENGINE_TYPE=baileys`.

**DoD:** the agent reads your last N WhatsApp messages and folds a summary into the
brief. It cannot send.

_Est: ~½ day (plus QR/session setup)._

---

## Stage 5 (optional, later) — Gated sends
Agent drafts email/WhatsApp replies; they send **only** on your tap.

**DoD:** a drafted reply is sent only after explicit approval, and the whole exchange is
in the audit log.

---

## Definition of Done — the whole system

You wake up, open Telegram or Obsidian, and see **one prioritized action** drawn from
your real calendar, inbox, and backlog — and **nothing ever acts without your tap.**

That is the finish line. If it's met, the project is *done*. Add a sixth stage only
deliberately, with its own DoD, after the first five have proven their worth in daily use.
