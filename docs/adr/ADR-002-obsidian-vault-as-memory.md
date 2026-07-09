# ADR-002: Obsidian vault (plain markdown) as the memory layer

**Status:** Accepted
**Date:** 2026-07-09

## Context
The agent already uses STATUS.md / BACKLOG.md / CLAUDE.md. We want a human-readable,
portable memory + dashboard the agent and the human share, reachable from mobile.

## Decision
Use an Obsidian vault — a folder of `.md` files. On the headless VPS the agent operates
on the files directly. A `vault-sync` sidecar git-pushes/pulls a private repo so Obsidian
on laptop/phone stays current. The Obsidian Local REST API/MCP plugin (which needs the GUI)
is used only on the human's devices, not on the VPS.

## Consequences
- (+) No lock-in; markdown is portable and diff-able; trivial backup.
- (+) One calm surface for prioritization (helps focus).
- (−) Git-sync conflicts possible if edited in two places at once → last-write-wins;
      keep the agent's writes scoped to daily notes + append patterns.
