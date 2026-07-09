# Architecture

## Deployment Topology

```mermaid
flowchart LR
    subgraph internet["Internet"]
        TGAPI["Telegram Bot API"]
        GOOG["Google APIs readonly"]
        WA["WhatsApp via Baileys"]
        GHREPO["Private vault git repo"]
    end

    subgraph host["VPS - Docker host, one internal network"]
        direction TB
        H["hermes gateway"]
        GM["google-mcp"]
        OW["openwa"]
        VS["vault-sync"]
        V[("vault volume")]
        HH[("hermes_home volume")]
        AU[("audit volume")]
        SESS[("openwa_session volume")]
    end

    H <--> TGAPI
    GM --> GOOG
    OW <--> WA
    VS <--> GHREPO

    H --> GM
    H --> OW
    H --- V
    H --- HH
    H --- AU
    VS --- V
    OW --- SESS
```

All services live on one internal Docker network. No Hermes dashboard or API port is
published by default. `openwa` is only started through the `openwa` profile.

## Daily Brief Flow

```mermaid
sequenceDiagram
    participant Cron as Hermes cron
    participant H as Hermes
    participant G as google-mcp
    participant WA as openwa
    participant Vault as vault
    participant TG as Telegram

    Cron->>H: run Bip daily brief prompt
    H->>Vault: read BIP, STATUS, BACKLOG, daily notes
    H->>G: read calendar and Gmail
    H->>WA: read WhatsApp context when enabled
    H->>H: choose one next action
    H->>Vault: write daily/YYYY-MM-DD.md
    H->>TG: send brief
    Note over Cron,H: cron_mode=deny; no actions from scheduled jobs
```

## Gated Action Flow

```mermaid
sequenceDiagram
    participant You as You in Telegram
    participant H as Hermes
    participant Audit as audit/actions.jsonl
    participant Tool as future hand

    You->>H: ask for an action
    H->>H: draft proposal
    H->>You: request manual approval
    H->>Audit: record proposed action
    You->>H: approve or deny
    H->>Audit: record decision
    H->>Tool: execute only when approved
    Tool-->>H: outcome
    H->>Audit: record outcome
```

Real send/deploy/spend hands are not attached during Stages 1-4. Stage 5 adds each hand
separately only when it can be approval-gated and audited.

## Component Detail

### hermes

Hermes is Bip's runtime: gateway, Telegram surface, cron runner, MCP client, session
state, shell context, and approval layer. It is packaged by `services/hermes/Dockerfile`
and stores runtime state in `hermes_home`.

### vault

The vault is the durable shared memory. `vault/BIP.md` is Bip's provider-neutral identity
source. `vault/CLAUDE.md` remains as a compatibility pointer. Hermes generates runtime
`SOUL.md` from `BIP.md` on startup.

### google-mcp

Google MCP exposes Calendar and Gmail with read-only scopes only. Widening scopes requires
a new ADR and a Stage 5 hand with approval and audit.

### openwa

OpenWA is optional WhatsApp read-only triage. It runs with `ENGINE_TYPE=baileys` and
`MCP_READONLY=true`. Use a spare number because WhatsApp Web automation carries ban risk.

### audit

`/audit/actions.jsonl` is the Bip governance contract. Hermes logs may be useful, but real
hands stay disabled until proposed, approved, denied, and executed events can be audited.
