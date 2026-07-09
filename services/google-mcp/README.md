# google-mcp - Calendar + Gmail read-only

This service exposes Google Calendar and Gmail to Hermes over MCP on the internal Docker
network.

Use an OAuth2 client and refresh token minted with read-only scopes only:

- `https://www.googleapis.com/auth/gmail.readonly`
- `https://www.googleapis.com/auth/calendar.readonly`

Widening scopes beyond read-only requires a new ADR and a Stage 5 hand with manual approval
and audit. Hermes should only receive read/list/summarize tools from this service during
Stages 1-4.
