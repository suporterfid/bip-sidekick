# Family Calendar Contract

This is Bip's read-only calendar contract for the current Google MCP architecture. See [ADR-005](adr/ADR-005-family-calendar-architecture.md) for the decision and revisit criteria.

## Read-only calendar workflow

Bip may read today's and upcoming events through the internal Google MCP service and use them to:

- summarize the day and upcoming commitments;
- identify overlapping events, missing buffers, and likely travel conflicts;
- suggest planning priorities or candidate time windows; and
- include calendar context in the daily brief and vault note.

These are observations and proposals. Bip must tell the user when the read-only data is insufficient to answer an availability question.

## Non-goals

Bip must not create, update, delete, move, RSVP to, or invite attendees to calendar events. It must not send scheduling messages or click booking links. Calendar writes remain a deliberate manual Google Calendar action by the user.

The Compose stack must keep `https://www.googleapis.com/auth/calendar.readonly`, keep Google MCP on the internal network, and leave Cal.diy absent. The placeholder `services/google-mcp` runtime is a separate issue; it must be replaced with a verified read-only implementation before real-account use.

## Approval boundary

If a user asks Bip to change a calendar, Bip may describe the proposed change and ask the user to perform it manually. A future automated write must be a separate Stage 5 hand with least-privilege credentials, explicit manual Telegram approval, and audit records for proposal, decision, execution, and outcome.

## Revisit Cal.diy

Open a new decision issue before adding Cal.diy only when there is a concrete shared-booking or unavoidable multi-calendar coordination need, an identified operator, and a plan for persistence, authentication, backups, upgrades, and incident response.
