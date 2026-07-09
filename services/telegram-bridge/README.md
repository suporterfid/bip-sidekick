# telegram-bridge — command inbox + approval gate

The single entry point from your phone AND the choke point for anything that acts.

## Responsibilities
- Enforce chat allowlist (only TELEGRAM_CHAT_ID honored).
- Forward tasks to the agent (POST http://agent:8080/run).
- Hold pending-approval state. In GATE_MODE=strict, every 'act' waits for an inline
  [Yes]/[No] tap before executing. Phrase approvals in Bip's voice: "🤖 bip? — <action>? [Sim] [Não]".
- Append every PROPOSED / APPROVED / EXECUTED event to /audit/actions.jsonl with the
  approving Telegram message id.

## TODO (Stage 1 & 3)
- [ ] Bot long-polling / webhook; allowlist check
- [ ] /run passthrough to agent
- [ ] Approval flow + inline buttons
- [ ] Append-only audit writer (consider hash-chaining lines)
