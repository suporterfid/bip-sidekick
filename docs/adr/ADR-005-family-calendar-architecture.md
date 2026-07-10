# ADR-005: Google Calendar read-only for family scheduling

Status: Accepted

## Context

Bip already connects Hermes to the internal `google-mcp` service. Google OAuth is restricted to Gmail and Calendar read-only scopes, and the project is read-only first. Issue #14 asks whether family scheduling should remain on Google MCP or add a self-hosted Cal.diy layer.

## Decision

Keep Google Calendar as the only calendar integration for now. Bip may read events and produce summaries, conflict findings, buffers, and planning suggestions. It must not create, update, delete, RSVP to, or invite attendees to events.

Cal.diy is deferred. No Cal.diy service, database, public port, OAuth client, or scheduler belongs in the current Compose stack.

## Governance

Keep `https://www.googleapis.com/auth/calendar.readonly`. Any future calendar write is a separate Stage 5 hand with a dedicated ADR, least-privilege credentials, manual Telegram approval, and audit records for proposal, decision, execution, and outcome.

## Consequences

The current workflow is smaller and observable, but event creation remains a deliberate manual Google Calendar action. The placeholder `services/google-mcp` runtime remains a separate issue: it must be replaced by a verified read-only Calendar implementation before real account use.

## Revisit triggers

Re-open this decision only for a concrete shared-booking requirement, an unavoidable multi-calendar coordination gap, and an identified operator for Cal.diy persistence, authentication, backups, upgrades, and incident response.
