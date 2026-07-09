# Hermes-Native Governed Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Bip Sidekick's stubbed `agent`, `telegram-bridge`, and `brief-engine` runtime with a Dockerized Hermes-native runtime governed by vault identity, read-only MCP, manual approvals, and explicit audit posture.

**Architecture:** Hermes runs as the single `core` runtime service from `services/hermes/Dockerfile`, with `/opt/data` as Hermes home, `/vault` as Bip's durable memory, and `/audit` as the governance log volume. `vault/BIP.md` becomes the provider-neutral identity source and startup generates Hermes `SOUL.md` from it. Google MCP and OpenWA remain sibling read-only services on the internal Docker network.

**Tech Stack:** Docker Compose, GNU Make, POSIX shell, Markdown docs, Hermes Agent Docker image, MCP over HTTP.

## Global Constraints

- Keep the deployment fully Dockerized; do not require host-level Hermes installation.
- Do not mount the Docker socket into Hermes.
- Do not publish Hermes dashboard or API ports by default.
- Keep Google and OpenWA read-only during Stages 1-4.
- Allow shell only inside the Hermes container context.
- Keep real send/deploy/spend hands unavailable until Stage 5 issues are implemented.
- Generate Hermes `SOUL.md` from `vault/BIP.md`, with a versioned fallback template.
- Keep `vault/CLAUDE.md` only as a compatibility pointer to `vault/BIP.md`.
- Run `docker compose config` and shell syntax checks before claiming the migration is valid.

---

## File Structure

- Create `services/hermes/Dockerfile`: thin wrapper around `nousresearch/hermes-agent:latest`.
- Create `services/hermes/entrypoint.sh`: initializes `/opt/data`, `config.yaml`, `.env`, `SOUL.md`, and cron prompt files before running `hermes gateway run`.
- Create `services/hermes/templates/BIP.md`: fallback provider-neutral Bip identity.
- Create `services/hermes/templates/config.yaml`: governed Hermes config with approvals and MCP servers.
- Create `services/hermes/templates/cron/daily-brief.md`: daily brief prompt.
- Create `services/hermes/README.md`: runtime package notes.
- Modify `docker-compose.yml`: add `hermes_home`, replace active runtime services with `hermes`.
- Modify `.env.example`: update Hermes provider, Telegram allowlist, cron, and removed `AGENT_URL` guidance.
- Modify `Makefile`: point logs and audit helpers at Hermes.
- Create `vault/BIP.md`: provider-neutral source of truth.
- Modify `vault/CLAUDE.md`: compatibility pointer.
- Modify docs and ADRs to describe Hermes-native architecture.

---

### Task 1: Add Bip Identity Source

**Files:**
- Create: `vault/BIP.md`
- Modify: `vault/CLAUDE.md`

**Interfaces:**
- Consumes: existing Bip instructions in `vault/CLAUDE.md`.
- Produces: `/vault/BIP.md`, which `services/hermes/entrypoint.sh` reads to generate `${HERMES_HOME}/SOUL.md`.

- [ ] **Step 1: Replace provider-specific identity with neutral source**

Create `vault/BIP.md` with:

```markdown
# BIP.md - Bip operating instructions

You are **Bip**, a friendly, loyal, read-only-first sidekick. You share the load,
suggest the next useful move, and wait for the human to decide before anything acts.

## Daily brief

Each morning:

1. Read today's calendar events through Google MCP with read-only scopes.
2. Read unread or flagged mail through Google MCP with read-only scopes.
3. Summarize recent WhatsApp messages through OpenWA MCP when that profile is enabled.
4. Read `/vault/BACKLOG.md`, `/vault/STATUS.md`, and recent `/vault/daily/` notes.
5. Choose exactly one next action.
6. Explain why that action matters in two or three concise sentences.
7. Write the brief to `/vault/daily/YYYY-MM-DD.md`.
8. Send the same brief to Telegram.

## Rules

- Never send, deploy, spend, delete, or mutate external systems from a cron job.
- If an interactive task needs an action, propose it and wait for manual approval.
- Treat `/vault` as the source of truth for priorities, status, backlog, and daily notes.
- Treat Hermes memories as optional scratch, not as a replacement for `/vault`.
- Keep answers warm, direct, and brief.
- Approval voice: `bip? - <action>? [Sim] [Nao]`.
```

- [ ] **Step 2: Keep the Claude compatibility pointer**

Replace `vault/CLAUDE.md` with:

```markdown
# CLAUDE.md - compatibility pointer

Bip's provider-neutral operating instructions now live in `BIP.md`.

Agents that still look for `CLAUDE.md` should read `BIP.md` first and treat it as the
source of truth for Bip identity, daily brief behavior, approval posture, and vault usage.
```

- [ ] **Step 3: Verify identity references**

Run: `rg -n "CLAUDE.md|BIP.md|SOUL.md" vault README.md docs services docker-compose.yml`

Expected: `vault/BIP.md` exists, `vault/CLAUDE.md` is only a pointer, and remaining
`CLAUDE.md` references are docs that will be updated in Task 5.

---

### Task 2: Add Hermes Docker Package

**Files:**
- Create: `services/hermes/Dockerfile`
- Create: `services/hermes/entrypoint.sh`
- Create: `services/hermes/templates/BIP.md`
- Create: `services/hermes/templates/config.yaml`
- Create: `services/hermes/templates/cron/daily-brief.md`
- Create: `services/hermes/README.md`

**Interfaces:**
- Consumes: `/vault/BIP.md`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `BRIEF_CRON`, `TZ`, provider keys, and internal MCP endpoints.
- Produces: `${HERMES_HOME}/SOUL.md`, `${HERMES_HOME}/config.yaml`, `${HERMES_HOME}/cron/bip-daily-brief.md`, and a running `hermes gateway run` process.

- [ ] **Step 1: Add Dockerfile**

```dockerfile
FROM nousresearch/hermes-agent:latest

USER root
RUN mkdir -p /opt/bip/templates/cron

COPY templates/ /opt/bip/templates/
COPY entrypoint.sh /opt/bip/entrypoint.sh

RUN chmod +x /opt/bip/entrypoint.sh && chown -R hermes:hermes /opt/bip

USER hermes
ENTRYPOINT ["/opt/bip/entrypoint.sh"]
CMD ["gateway", "run"]
```

- [ ] **Step 2: Add entrypoint**

```sh
#!/usr/bin/env sh
set -eu

HERMES_HOME="${HERMES_HOME:-/opt/data}"
export HERMES_HOME

mkdir -p "$HERMES_HOME" "$HERMES_HOME/cron" "$HERMES_HOME/logs" /vault/daily /audit

if [ ! -f /vault/BIP.md ]; then
  cp /opt/bip/templates/BIP.md /vault/BIP.md
fi

{
  printf '%s\n' '# SOUL.md - generated for Hermes runtime'
  printf '%s\n' ''
  printf '%s\n' 'This file is generated at container startup from /vault/BIP.md.'
  printf '%s\n' 'Edit /vault/BIP.md, not this file.'
  printf '%s\n' ''
  cat /vault/BIP.md
  printf '%s\n' ''
  printf '%s\n' '## Hermes runtime notes'
  printf '%s\n' ''
  printf '%s\n' '- /vault is the source of truth for status, backlog, identity, and daily notes.'
  printf '%s\n' '- Hermes memories are optional scratch and do not replace /vault.'
  printf '%s\n' '- Cron briefs are read-only and must not execute send, deploy, spend, or destructive shell actions.'
  printf '%s\n' '- Dangerous interactive tools require manual approval.'
} > "$HERMES_HOME/SOUL.md"

if [ ! -f "$HERMES_HOME/config.yaml" ]; then
  cp /opt/bip/templates/config.yaml "$HERMES_HOME/config.yaml"
fi

cp /opt/bip/templates/cron/daily-brief.md "$HERMES_HOME/cron/bip-daily-brief.md"

if [ -n "${TELEGRAM_CHAT_ID:-}" ] && [ -z "${TELEGRAM_ALLOWED_USERS:-}" ]; then
  export TELEGRAM_ALLOWED_USERS="$TELEGRAM_CHAT_ID"
fi

exec hermes "$@"
```

- [ ] **Step 3: Add governed config template**

```yaml
approvals:
  mode: manual
  timeout: 60
  cron_mode: deny
  mcp_reload_confirm: true
  destructive_slash_confirm: true

tool_loop_guardrails:
  hard_stop_enabled: true
  hard_stop_after:
    exact_failure: 5
    idempotent_no_progress: 5

terminal:
  env_passthrough:
    - TZ

mcp_servers:
  google:
    url: "http://google-mcp:8081/mcp"
    enabled: true
    timeout: 120
    connect_timeout: 60
    supports_parallel_tool_calls: false
    tools:
      exclude:
        - send_email
        - send_message
        - create_event
        - update_event
        - delete_event
      resources: true
      prompts: false

  whatsapp:
    url: "http://openwa:3000/mcp"
    enabled: true
    timeout: 120
    connect_timeout: 60
    supports_parallel_tool_calls: false
    tools:
      exclude:
        - send_message
        - send
        - reply
        - delete_message
      resources: true
      prompts: false
```

- [ ] **Step 4: Add daily brief prompt**

```markdown
# Bip daily brief

Read `/vault/STATUS.md`, `/vault/BACKLOG.md`, recent `/vault/daily/` notes, today's
calendar events, unread or flagged mail, and WhatsApp context when the MCP server is
available.

Choose exactly one next action for today. Explain why in two or three concise sentences.

Write the brief to `/vault/daily/YYYY-MM-DD.md` and send the same brief to Telegram.

Do not send email, send WhatsApp messages, deploy, spend money, delete data, or mutate
external systems. If a useful next step requires action, describe the proposed action and
stop for manual approval.
```

- [ ] **Step 5: Add package README**

```markdown
# hermes - Bip runtime

This image wraps the official Hermes Agent container for Bip Sidekick.

Runtime state lives in `/opt/data`. Bip's human-readable memory and identity live in
`/vault`. On startup the entrypoint generates `/opt/data/SOUL.md` from `/vault/BIP.md`.

The service runs `hermes gateway run` and keeps dashboard/API ports unpublished by
default. Shell access is container-scoped; the Docker socket and host filesystem are not
mounted.
```

- [ ] **Step 6: Verify shell syntax**

Run: `bash -n services/hermes/entrypoint.sh`

Expected: no output and exit code `0`.

---

### Task 3: Migrate Compose And Make Targets

**Files:**
- Modify: `docker-compose.yml`
- Modify: `Makefile`
- Modify: `.env.example`

**Interfaces:**
- Consumes: `services/hermes/` package from Task 2.
- Produces: `make up-core`, `make up-gate`, `make logs SVC=hermes`, and `make audit` commands for Hermes-native runtime.

- [ ] **Step 1: Add `hermes_home` volume and Hermes service**

Add this service in `docker-compose.yml`:

```yaml
  hermes:
    profiles: ["core"]
    build: ./services/hermes
    container_name: bip-hermes
    command: ["gateway", "run"]
    environment:
      HERMES_HOME: /opt/data
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}
      TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN}
      TELEGRAM_CHAT_ID: ${TELEGRAM_CHAT_ID}
      TELEGRAM_ALLOWED_USERS: ${TELEGRAM_ALLOWED_USERS:-${TELEGRAM_CHAT_ID}}
      BRIEF_CRON: ${BRIEF_CRON:-0 6 * * *}
      TZ: ${TZ:-America/Sao_Paulo}
    volumes:
      - hermes_home:/opt/data
      - vault:/vault
      - audit:/audit
    depends_on: [google-mcp]
    restart: unless-stopped
    networks: [internal]
```

Also add:

```yaml
  hermes_home:
```

- [ ] **Step 2: Remove active runtime stubs**

Remove active `agent`, `brief-engine`, and `telegram-bridge` services from
`docker-compose.yml`. Leave their directories in `services/` for superseded docs until
Task 5 updates them.

- [ ] **Step 3: Update Makefile commands**

Set:

```makefile
up-core: ## Stage 1-2: Hermes + senses + memory + daily brief
	$(COMPOSE) --profile core up -d --build

up-gate: ## Stage 3: verify Hermes manual approvals and audit posture
	$(COMPOSE) --profile core up -d --build hermes
	@echo ">> Gate target active. Verify approvals.mode=manual and approvals.cron_mode=deny in Hermes."

logs: ## Tail logs. Usage: make logs SVC=hermes
	$(COMPOSE) logs -f $(SVC)

audit: ## Tail the append-only action log
	docker exec bip-hermes sh -lc 'touch /audit/actions.jsonl && tail -f /audit/actions.jsonl'
```

- [ ] **Step 4: Update `.env.example`**

Keep `ANTHROPIC_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, Google, vault sync,
OpenWA, `BRIEF_CRON`, `TZ`, and `GATE_MODE`. Add:

```dotenv
TELEGRAM_ALLOWED_USERS=     # defaults to TELEGRAM_CHAT_ID when empty
```

Remove `CLAUDE_CODE_OAUTH_TOKEN` from the primary auth section and document provider keys
as Hermes provider keys.

- [ ] **Step 5: Validate Compose shape**

Run: `docker compose config`

Expected: rendered config includes `bip-hermes`, `hermes_home`, `google-mcp`, and
`vault-sync`; rendered config does not include active `bip-agent`, `bip-brief-engine`, or
`bip-telegram-bridge` services.

---

### Task 4: Add Runtime Verification Guards

**Files:**
- Create: `scripts/validate-hermes-migration.sh`

**Interfaces:**
- Consumes: repository files after Tasks 1-3.
- Produces: a repeatable static validation command for the migration.

- [ ] **Step 1: Add validation script**

```sh
#!/usr/bin/env sh
set -eu

test -f services/hermes/Dockerfile
test -x services/hermes/entrypoint.sh
test -f services/hermes/templates/config.yaml
test -f services/hermes/templates/BIP.md
test -f vault/BIP.md

if grep -q 'docker.sock' docker-compose.yml; then
  echo "docker socket must not be mounted into Hermes" >&2
  exit 1
fi

if grep -q 'ports:' docker-compose.yml && grep -A12 'hermes:' docker-compose.yml | grep -q 'ports:'; then
  echo "Hermes must not publish ports by default" >&2
  exit 1
fi

grep -q 'cron_mode: deny' services/hermes/templates/config.yaml
grep -q 'mode: manual' services/hermes/templates/config.yaml
grep -q 'MCP_READONLY: "true"' docker-compose.yml
```

- [ ] **Step 2: Make it executable**

Run: `git update-index --chmod=+x scripts/validate-hermes-migration.sh`

Expected: Git tracks executable bit for the validation script.

- [ ] **Step 3: Run static checks**

Run:

```bash
bash -n services/hermes/entrypoint.sh
bash -n scripts/validate-hermes-migration.sh
bash scripts/validate-hermes-migration.sh
docker compose --profile core --profile openwa config
```

Expected: all commands exit `0`.

---

### Task 5: Update Documentation And ADR

**Files:**
- Create: `docs/adr/ADR-004-hermes-native-runtime.md`
- Modify: `README.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/SECURITY.md`
- Modify: `services/agent/README.md`
- Modify: `services/telegram-bridge/README.md`
- Modify: `services/brief-engine/README.md`

**Interfaces:**
- Consumes: runtime shape from Tasks 1-4.
- Produces: docs that describe Hermes-native deployment as the current architecture.

- [ ] **Step 1: Add ADR-004**

```markdown
# ADR-004 - Hermes-native runtime

## Status

Accepted

## Context

The original reference architecture split the runtime across custom stubs:
`agent`, `telegram-bridge`, and `brief-engine`. Hermes now provides the gateway, cron,
Telegram integration, session runtime, MCP integration, and dangerous-command approvals
that those stubs were meant to grow into.

## Decision

Use Hermes as Bip's native runtime. Keep Bip's differentiators outside Hermes core:
`/vault` as shared memory, `vault/BIP.md` as identity, read-only MCP senses, manual
approval policy, and explicit audit posture.

## Consequences

- Fewer custom services to maintain.
- Deployment remains Docker Compose based.
- Stage 5 hands remain deferred until each hand is approval-gated and auditable.
- Hermes logs are not automatically the full Bip JSONL audit contract; that mirror is
  tracked separately.
```

- [ ] **Step 2: Update superseded service READMEs**

Each superseded README should start with:

```markdown
> Superseded by `services/hermes/` in the Hermes-native runtime. This directory is kept
> only as historical context while the migration settles.
```

- [ ] **Step 3: Update top-level docs**

Update diagrams, component tables, quickstart commands, roadmap stage names, and security
rules so they describe `hermes` as the runtime. Keep the non-goals and read-only-first
governance language.

- [ ] **Step 4: Check for stale primary-runtime wording**

Run: `rg -n "custom HTTP|/run|telegram-bridge|brief-engine|Claude Code as primary|CLAUDE_CODE_OAUTH_TOKEN" README.md docs services .env.example docker-compose.yml Makefile`

Expected: matches only appear in superseded service notes, ADR historical context, or
explicit statements that those paths are no longer primary.

---

### Task 6: Final Verification And Commit

**Files:**
- Stage all files changed by Tasks 1-5.

**Interfaces:**
- Consumes: completed migration edits.
- Produces: one implementation commit for the governed Hermes-native migration.

- [ ] **Step 1: Run verification**

Run:

```bash
bash -n services/hermes/entrypoint.sh
bash -n scripts/validate-hermes-migration.sh
bash scripts/validate-hermes-migration.sh
docker compose --profile core --profile openwa config
git status --short
```

Expected: syntax and validation commands pass, Compose renders successfully, and Git shows
only intentional migration files.

- [ ] **Step 2: Commit implementation**

Run:

```bash
git add .env.example Makefile README.md docker-compose.yml docs scripts services vault
git commit -m "Migrate runtime to Hermes-native governance"
```

Expected: commit succeeds and `git status --short --branch` shows a clean working tree
apart from branch tracking metadata.

---

## Self-Review

Spec coverage:

- Dockerized Hermes package: Task 2.
- Compose migration: Task 3.
- Provider-neutral identity: Task 1 and Task 2.
- Manual approvals and cron deny: Task 2 and Task 4.
- MCP read-only filters: Task 2 and Task 4.
- Container-scoped shell: Task 2, Task 3, and Task 5.
- Audit posture: Task 3, Task 5, and Task 6.
- Documentation and ADR: Task 5.
- Verification: Task 4 and Task 6.

Placeholder scan:

- The plan contains no unresolved fill-ins and no code step without concrete content.

Type and name consistency:

- `HERMES_HOME` is `/opt/data` across Dockerfile, entrypoint, Compose, and docs.
- `vault/BIP.md` is the identity source across all tasks.
- `services/hermes/templates/config.yaml` is the governed config template across all tasks.
