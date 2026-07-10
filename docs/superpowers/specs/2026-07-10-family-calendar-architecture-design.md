# Family Calendar Architecture Design

## Decision

Keep Google Calendar as Bip's only calendar integration for the current stage. Bip uses the
existing Google MCP boundary for read-only calendar context and produces advisory responses;
it must not create, update, delete, RSVP to, or otherwise mutate calendar events. Cal.diy is
deferred until a concrete coordination need cannot be served by Google Calendar plus an
advisory workflow.

## Context

The active compose stack gives Hermes access to `google-mcp` on the internal network and pins
Google OAuth to `calendar.readonly` and `gmail.readonly`. Hermes is read-only first, and cron
jobs may write the daily vault note and deliver the brief to Telegram but cannot mutate external
systems. The current `services/google-mcp` image is a stub, so this decision defines the
architecture and readiness contract; it does not claim that a production Calendar MCP server is
already available.

## Requirements

### Read-first calendar experience

- Bip may summarize today's and upcoming events, identify time conflicts, flag missing travel
  buffers, and suggest planning priorities.
- A family-planning request must return observations and proposed options only. The user owns
  the final scheduling action in Google Calendar.
- Daily briefs may use calendar context and write their normal vault note. They must not modify
  calendars or send invitations.
- Bip must say explicitly when requested availability or a proposed event cannot be determined
  from the read-only calendar data it has.

### Integration and security boundary

- `google-mcp` remains the sole calendar sense and stays internal to Docker Compose.
- The only allowed Calendar OAuth scope is
  `https://www.googleapis.com/auth/calendar.readonly`.
- Hermes' read-only tool filters continue to exclude create, update, delete, reply, and send
  operations.
- No Cal.diy service, database, public port, OAuth client, or scheduler is introduced in this
  issue.
- Any future calendar write capability is a separate Stage 5 hand. It requires a dedicated ADR,
  least-privilege credentials, manual Telegram approval, and audit records linking proposal,
  decision, execution, and outcome.

### Readiness gap and operational next step

The placeholder `google-mcp` container cannot yet provide live Calendar data. Replacing that
stub with a maintained implementation that exposes only list/read Calendar tools is a separate
runtime integration issue. It must prove its tool inventory and scopes before it is attached to
real accounts; this issue must not widen scopes merely to compensate for the stub.

## Alternatives considered

1. **Google MCP only (selected).** Reuses the existing identity and network boundary, keeps
   scheduling advisory, and has no new persistence or public service.
2. **Deploy Cal.diy now.** Adds scheduling flexibility, but requires a new hosted service,
   authentication, persistence, operations, and a write-path governance design before the
   project has validated a need for them.
3. **Hybrid Google plus Cal.diy.** May be appropriate later for a shared booking surface, but
   duplicates calendar concerns and creates integration work without improving the current
   read-first daily-brief workflow.

## Implementation shape

The implementation is documentation and guardrail-oriented:

1. Add an ADR that records Google Calendar as the current read-only source of truth and defines
   the criteria for reconsidering Cal.diy.
2. Add a concise operator guide describing supported advisory requests, explicit non-goals, and
   the external action handoff to the user.
3. Link the guide from the roadmap and security documentation so operators do not mistake
   calendar suggestions for calendar automation.
4. Add a focused validation script that asserts the documented decision remains consistent with
   the Compose scope, Google MCP contract, and absence of a Cal.diy runtime service.

## Acceptance criteria mapping

| Issue criterion | Design response |
| --- | --- |
| Concrete recommendation with tradeoffs | Google MCP only now; alternatives and costs are recorded above. |
| Short-term versus self-hosted scheduling investment | Advisory Google workflow now; Cal.diy only after explicit revisit triggers. |
| Approval-first calendar mutation rules | Writes are a separate Stage 5 hand with approval and audit requirements. |
| Clear next implementation step | Replace the Google MCP stub in a separate issue with a verified read-only Calendar implementation. |

## Revisit triggers

Create a new decision issue before considering Cal.diy when at least one of these is true:

- The family needs a shared external booking page or availability polling that Google Calendar
  cannot provide within the read-only boundary.
- Multiple independently managed calendars require a unified scheduling workflow that cannot be
  solved by read-only summaries and manual Google Calendar actions.
- The project has a concrete operator for a self-hosted scheduler and can fund its database,
  backups, authentication, updates, and incident response.

Until then, this architecture deliberately favors a smaller, observable, advisory system.
