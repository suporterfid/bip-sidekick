# google-mcp — Calendar + Gmail (READ-ONLY)

Self-hosted Google Workspace MCP server. On a headless VPS you don't get claude.ai's
managed connectors, so run this with your own OAuth2 client + refresh token, minted with
READ-ONLY scopes only:
  - https://www.googleapis.com/auth/gmail.readonly
  - https://www.googleapis.com/auth/calendar.readonly

Use a maintained community Google Workspace MCP image, or implement a thin server.
Widening scopes beyond read-only requires a new ADR (see docs/adr).

## TODO (Stage 2)
- [ ] Choose/build the MCP server; pin the image
- [ ] Mint refresh token offline with read-only scopes
- [ ] Expose MCP over http on :8081; confirm agent can list events + unread mail
