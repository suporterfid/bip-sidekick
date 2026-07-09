# Security & Governance

The design is **read-only-first**: the agent's default reach is observation. Anything
that changes the world is a gated exception. This mirrors the Harness Worker-Agent
governance pattern (sandboxing, scoped credentials, policy checkpoints, audit trail) —
applied as a **pattern at solo scale**, without adopting an enterprise platform.

## The four rules

1. **Read-only by default.**
   Senses (`google-mcp`, `openwa`) hold read scopes only. There is no code path from a
   sense to a mutation. Widening a scope requires editing `.env` *and* recording an ADR.

2. **Scoped keys per tool.**
   Each MCP server / integration gets its own least-privilege credential. Compromise of
   one credential does not grant the others. Nothing shares a "god key."

3. **Human tap for anything that acts.**
   Send / deploy / spend are "hands." They are unreachable except through a Telegram
   approval. `GATE_MODE=strict` means *every* act is confirmed individually.

4. **Append-only audit.**
   Every proposed, approved, and executed action is written to `audit/actions.jsonl`
   (who / what / when / outcome) and mirrored into the vault. Silent action is a bug.

## Credential handling

- Secrets live in `.env` (gitignored) or Docker secrets — never in the image or the repo.
- Containers run **non-root** where the base image allows (`user:` set in compose).
- Filesystems are `read_only: true` with a `tmpfs` for scratch where feasible.
- The `openwa_session` volume and `GOOGLE_REFRESH_TOKEN` are the crown jewels — losing
  the session lets someone impersonate your WhatsApp; losing the refresh token grants
  read access to mail/calendar. Back them up encrypted; rotate on any suspicion.

## Attack surface (STRIDE-lite)

| Threat | Vector | Mitigation |
|---|---|---|
| **Spoofing** | Someone messages the bot | Chat allowlist: only `TELEGRAM_CHAT_ID` is honored |
| **Tampering** | Altered audit log | Append-only file; back up off-host; consider hash-chaining |
| **Repudiation** | "The agent did X on its own" | Every act logged with the approving message id |
| **Info disclosure** | Leaked mail/WhatsApp content | Read scopes minimal; vault repo is **private**; TLS to Google |
| **DoS** | Message flood | Bridge rate-limits; only one chat honored anyway |
| **Elevation** | Sense → act path | Architecturally absent: senses are read-only, gate holds act creds |

## <a name="whatsapp"></a>WhatsApp-specific notes

- OpenWA's Baileys/whatsapp-web.js engines **emulate WhatsApp Web** on a real number.
  This carries a genuine account-ban risk. Use a **spare number** you can afford to lose,
  keep traffic human-like, and never bulk-message.
- This stack uses WhatsApp **read-only for triage**. It is *not* a customer-facing bot.
  Meta's 2026 policy restricting general-purpose AI chatbots on the Business API is about
  outbound automated chat; personal read-only triage is a different use, but review
  current terms before you point it anywhere client-facing.

## Before you point it at real accounts

- [ ] `.env` is gitignored and contains no secrets in git history
- [ ] Google refresh token minted with **read-only** scopes, verified
- [ ] Telegram chat allowlist set and tested (a message from another account is ignored)
- [ ] `GATE_MODE=strict`; confirmed an "act" blocks until you reply
- [ ] Audit log writing and backed up off-host
- [ ] OpenWA on a spare number, `MCP_READONLY=true` confirmed
- [ ] Vault git repo is **private**
