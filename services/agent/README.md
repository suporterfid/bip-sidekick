# agent - superseded runtime stub

> Superseded by `services/hermes/` in the Hermes-native runtime. This directory is kept
> only as historical context while the migration settles.

The original plan used this service for a custom agent runtime and HTTP `/run` shim.
Hermes now owns the brain, MCP session runtime, Telegram gateway, cron brief, and approval
surface.

`docker-compose.yml` still builds this directory as the tiny `vault-sync` utility image
because it already contains git and shell tooling. Do not add agent command handling here;
new runtime work belongs in `services/hermes/`.
