# Read-only MCP Contract

This is the Stage 1-4 read-only MCP contract for Bip Sidekick.

Hermes may connect to MCP senses over the Docker internal network:

- Google MCP at `http://google-mcp:8081/mcp`.
- OpenWA MCP at `http://openwa:3000/mcp` when the `openwa` profile is enabled.

The Google service must use only Gmail and Calendar read-only OAuth scopes. The OpenWA
service must run with `MCP_READONLY=true`. Neither service publishes a host port in the
default deployment.

Hermes MCP tool filters must exclude send, reply, create, update, delete, deploy, spend,
charge, and purchase-style tool names during Stages 1-4. MCP resources may remain enabled
so Bip can read context, but MCP prompts stay disabled.

Stage 5 write-capable hands must be separate tools with least-privilege credentials,
manual Telegram approval, and `/audit/actions.jsonl` coverage. Do not widen MCP scopes or
remove mutation-tool filters to make a write hand work.

GitHub review is documented separately in [`docs/GITHUB_REVIEW.md`](GITHUB_REVIEW.md) and is
not attached to the current MCP stack.

Validate this contract with:

```bash
python3 scripts/validate-readonly-mcp.py
```
