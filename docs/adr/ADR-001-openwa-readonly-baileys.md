# ADR-001: WhatsApp via OpenWA, Baileys engine, read-only

**Status:** Accepted
**Date:** 2026-07-09

## Context
We want WhatsApp triage in the daily brief. Options: official Cloud API (approval,
templates, 24h window), managed gateways (Z-API), or self-hosted OSS (Evolution, WPPConnect,
OpenWA). We already run a NestJS stack and want the agent to reach WhatsApp over MCP.

## Decision
Use our OpenWA fork because it ships a built-in MCP server (fewer moving parts than a
custom bridge) and matches our NestJS/TypeScript stack. Run `ENGINE_TYPE=baileys`
(websocket, no headless Chromium → lighter on a small VPS) and `MCP_READONLY=true`.

## Consequences
- (+) Agent reaches WhatsApp natively over MCP; no custom bridge to build.
- (+) Same stack we can read/debug/extend.
- (−) WhatsApp-Web emulation → account-ban risk. Mitigate with a spare number.
- (−) OpenWA is younger than Evolution API; we own the fork's maintenance. Track upstream.
