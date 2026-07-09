# agent — the brain

Claude Code running headless on the VPS under the Hermes framework, exposing a small
HTTP shim on :8080 so `brief-engine` and `telegram-bridge` can invoke tasks.

## Auth trade-off
- `ANTHROPIC_API_KEY`: bills per token; predictable for scheduled/headless runs. Recommended for the cron brief.
- `CLAUDE_CODE_OAUTH_TOKEN`: from a Claude subscription (e.g. Max). Intended for interactive use — confirm current terms before relying on it for unattended jobs.

## Responsibilities
- Register MCP servers from /mcp/.mcp.json (google, whatsapp — both read-only).
- Read/write the vault. Read the audit log.
- NEVER hold send/deploy credentials. Propose 'acts'; the gate executes them.

## TODO (Stage 1–2)
- [ ] HTTP shim: POST /run { prompt } -> runs a Claude Code task
- [ ] Wire mcp config; confirm google MCP reachable
- [ ] daily-brief prompt (see vault/CLAUDE.md)
