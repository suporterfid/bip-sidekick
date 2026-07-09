# GitHub Issue Priority Plan

Context: this plan is based on the open GitHub issues in `suporterfid/bip-sidekick` and the
current `main` checkout as of 2026-07-09.

## Executive read

The repo already looks past the original "Hermes-native migration" design stage. That means
the first priority should not be blindly implementing issues `#1`-`#10` in numeric order.
Instead, we should:

1. run a validation-and-closure pass on the foundational issues that now appear implemented
   in code or docs,
2. finish the runtime behaviors that still need real proof in a running environment, and
3. only then move into new user-facing capabilities.

## Current state reading

These surfaces strongly suggest that much of the base migration already exists:

- `docker-compose.yml` already runs `hermes`, `google-mcp`, `vault-sync`, and optional
  `openwa`.
- `Makefile` already exposes `up-core`, `up-gate`, `up-openwa`, and `audit`.
- `services/hermes/` already exists with runtime templates and an entrypoint that generates
  `SOUL.md` from `vault/BIP.md`.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/SECURITY.md`, and
  `docs/adr/ADR-004-hermes-native-runtime.md` already describe Hermes-native architecture.

Because of that, several open issues look more like "verify and close" than "implement from
scratch".

## Recommended implementation waves

### Wave 0 - Validation and closure sweep

Goal: clean up stale foundation work before new feature work.

Issues:

- `#1` Hermes-native runtime package and Docker deployment
- `#2` Bip identity source: `vault/BIP.md` generates Hermes `SOUL.md`
- `#3` Compose migration to Hermes
- `#5` Read-only MCP integration and tool filtering
- `#7` Container-scoped shell for Hermes with approval guardrails
- `#10` Documentation and ADR update for Hermes-native architecture

Why first:

- The repo already contains code and docs that map directly to these issues.
- Leaving these open makes the backlog look larger and less trustworthy than it really is.
- Any missing detail found here should become a narrow follow-up issue, not keep a broad
  migration epic open indefinitely.

Exit criteria:

- Verify each issue against the running stack where needed.
- Close the issue if the acceptance criteria are satisfied.
- If not satisfied, create a small follow-up bug and relabel the parent issue accordingly.

### Wave 1 - Prove the governed runtime in practice

Goal: finish the parts that matter most to safe day-to-day use.

Order:

1. `#4` Hermes Telegram gateway allowlist and manual approvals
2. `#6` Daily brief cron in Hermes
3. `#8` Append-only audit mirror for approvals and executed actions

Why this order:

- `#4` is the governance gate for interactive use.
- `#6` is the first end-user outcome the platform promises.
- `#8` should be validated after approvals and cron behavior are observable in the real
  runtime.

Notes:

- `#8` is the most likely place where repo docs are ahead of runtime reality.
- Do not start Stage 5 write-capability work before this wave is proven.

### Wave 2 - Backlog operations hygiene

Goal: make the GitHub backlog operational after the foundation is cleaned up.

Issue:

- `#11` Provision GitHub Project backlog and saved views

Why here:

- The project board becomes much more useful after Wave 0 closes or re-scopes the stale
  migration issues.
- This can run in parallel with Wave 1 if GitHub project scopes are already available.

### Wave 3 - First read-only features with immediate value

Goal: ship advisory capabilities that reuse existing senses and stay inside current
governance limits.

Order:

1. `#15` Gmail-based bill reminders and overdue account detection
2. `#14` Family calendar orchestration and scheduling architecture
3. `#17` On-demand GitHub code review and patch workflow for personal projects

Why this order:

- `#15` has a clear user outcome and fits the existing Gmail read-only posture.
- `#14` builds naturally on the existing calendar sense and can stay advisory-first.
- `#17` is high value, but its write path is more sensitive and should stay review-first
  until approvals and audit are fully trusted.

### Wave 4 - Draft-first creation and assistance flows

Goal: expand Bip into new domains without requiring autonomous mutation on day one.

Order:

1. `#16` Technical content pipeline for alexconnect.io via WordPress
2. `#12` Alexa voice interface and skill for Bip agent
3. `#18` User support copilot with RAG baseline and KAG evaluation

Why this order:

- `#16` can start with draft generation only and has a straightforward approval boundary.
- `#12` adds a new interface surface and operational complexity, so it should follow a more
  mature core.
- `#18` is broader, knowledge-heavy, and likely needs a more deliberate source-of-truth
  design before it becomes reliable.

### Wave 5 - Real write hands, but only as split issues

Goal: enable narrowly scoped actions only after governance proof exists.

Issue:

- `#9` Gated send and deploy hands for Stage 5

Recommendation:

- Treat `#9` as an umbrella issue, not as one implementation ticket.
- Split it into concrete sub-issues when there is a real need, for example:
  - "Create WordPress draft under approval"
  - "Create GitHub PR under approval"
  - "Send WhatsApp message under approval"

Why not earlier:

- The current roadmap explicitly says mutation tools should wait until approvals and audit
  are proven.
- Building generic write capability too early will increase surface area before the core
  operating model is trustworthy.

### Wave 6 - Large new subsystem

Goal: defer the heaviest bet until the core loop is stable.

Issue:

- `#13` Home camera monitoring pipeline with ML events and LLM-assisted model improvement

Why last:

- Highest infrastructure, privacy, hardware, retention, and ML complexity in the backlog.
- It is better handled once Bip's daily operating loop and governance model are already
  boring and dependable.

## Suggested `next-up` shortlist

If we want a very small practical queue for the next passes, I would mark these as the
working shortlist:

- `#4` Hermes Telegram gateway allowlist and manual approvals
- `#6` Daily brief cron in Hermes
- `#8` Append-only audit mirror for approvals and executed actions
- `#11` Provision GitHub Project backlog and saved views

## Recommended total order

This is the order I would use for actual execution planning:

1. Wave 0 closure sweep: `#1`, `#2`, `#3`, `#5`, `#7`, `#10`
2. Wave 1 governed runtime proof: `#4` -> `#6` -> `#8`
3. Wave 2 backlog operations: `#11`
4. Wave 3 read-only value: `#15` -> `#14` -> `#17`
5. Wave 4 draft-first expansion: `#16` -> `#12` -> `#18`
6. Wave 5 split and implement the first concrete child of `#9`
7. Wave 6 heavyweight subsystem: `#13`

## Practical next action

The highest-leverage next pass is not a new feature. It is a focused closure and validation
pass for `#1`, `#2`, `#3`, `#5`, `#7`, and `#10`, followed immediately by runtime proof for
`#4`, `#6`, and `#8`.
