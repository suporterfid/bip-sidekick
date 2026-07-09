# openwa — WhatsApp read-only triage

Runs your OpenWA fork. Two ways to provide it:
1. Use a published image: set `image: ghcr.io/suporterfid/openwa:latest` in compose (default), or
2. Vendor the source: `git submodule add https://github.com/suporterfid/OpenWA services/openwa/OpenWA`
   and switch the compose service to `build: ./services/openwa/OpenWA`.

Config (see .env / compose):
- ENGINE_TYPE=baileys   # lighter than whatsapp-web.js; no headless Chromium
- MCP_ENABLED=true
- MCP_READONLY=true      # triage only — the agent cannot send
- API_KEY=${OPENWA_API_KEY}

First run prints a QR in the logs (`make logs SVC=openwa`). Scan with a SPARE number.
See docs/SECURITY.md#whatsapp for the ban-risk caveat.
