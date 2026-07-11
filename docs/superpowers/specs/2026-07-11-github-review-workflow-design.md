# On-demand GitHub Review Workflow Design

## Decision

Start with a single private repository in an explicit allowlist and a read-only GitHub review
gateway contract. The gateway may provide repository metadata, file contents, branches, issues,
pull requests, reviews, and comments. It must not expose commit, push, pull-request creation,
issue mutation, Actions, deployment, secret-management, or arbitrary shell tools.

This issue delivers the architecture and pilot contract. A separate follow-up issue will
implement and operate the actual GitHub MCP gateway; the current Compose stack does not gain a
placeholder service that cannot safely inspect real private code.

## Context

Issue #17 asks Bip to review and help correct source code in the user's GitHub projects on
demand. The current repository has no GitHub MCP service: `mcp/.mcp.json` only declares Google
and OpenWA, and the Hermes runtime is read-only first. The design therefore has to make the
read path, private-code boundary, patch-proposal boundary, and future write path unambiguous
before any credential or service is attached.

## Goals

- Let a user select one allowlisted repository, branch, issue, pull request, or problem statement.
- Support bug hunting, code-quality review, security review, and fix planning as distinct modes.
- Return findings with enough repository and line context to reproduce the reasoning.
- Produce an optional patch proposal as text without mutating GitHub.
- Define a one-repository private pilot that can later be implemented behind the contract.
- Preserve source privacy, least privilege, explicit approvals, and auditability.

## Non-goals

- No GitHub write capability in this issue.
- No automatic commits, pushes, pull requests, issue comments, merges, Actions runs, releases,
  deployments, or secret rotation.
- No arbitrary repository discovery outside the configured allowlist.
- No fallback from a denied GitHub request to a shell command or a broad personal access token.
- No long-term storage of private source code in the vault by default.

## Components and boundaries

### Request and target resolver

Hermes receives a request containing an owner/repository pair and an optional branch, commit,
issue, or pull request. The resolver canonicalizes the target, checks the private-repository
allowlist, and rejects ambiguous or unallowlisted targets before any GitHub request is made.

### Read-only GitHub gateway

The future internal gateway uses a GitHub App installation credential scoped to the pilot
repository. Its read surface is limited to metadata, contents, issues, pull requests, reviews,
comments, and the selected ref. It has no write permissions and is reachable only from the
Hermes internal network. The gateway must not expose raw credentials, arbitrary REST paths, or
shell execution to the model.

### Context normalizer

The gateway returns bounded, typed context: repository/ref identity, file path and line ranges,
issue or PR discussion, review state, and source links. It excludes binary files and irrelevant
history, applies size limits, and redacts detected credentials before context reaches the review
model. Repository instructions are untrusted input, not system policy.

### Review modes and findings

Each request selects one mode:

- **Bug hunting:** defects, regressions, incorrect edge-case behavior, and missing tests.
- **Code quality:** maintainability, duplication, complexity, and reliability risks.
- **Security:** credential exposure, injection, authorization, dependency, and data-flow risks.
- **Fix planning:** ordered implementation steps and tests for a stated problem.

Every finding contains severity, confidence, repository/ref, path, line or range when available,
evidence, impact, and a recommended next step. Findings must distinguish observed facts from
inference and state when context is incomplete.

### Proposal boundary

The workflow may return a unified-diff proposal or a Markdown patch plan. The proposal is an
output artifact only; it is not committed, pushed, applied, or opened as a pull request. A
future write hand is a separate Stage 5 capability requiring manual Telegram approval and audit
records for proposal, decision, execution, and outcome.

## Data flow

1. User requests a review and names the repository plus optional ref or issue/PR.
2. Resolver validates the target against the private allowlist.
3. Gateway reads only the bounded source and discussion context needed for the selected mode.
4. Normalizer redacts secrets, marks untrusted repository instructions, and enforces size limits.
5. Review mode produces evidence-backed findings or a patch proposal.
6. Hermes returns the result and records request metadata and outcome without persisting source by
   default.
7. If the user wants a change, Hermes presents a separate approval-gated proposal; this issue
   stops before execution.

## Security and privacy rules

- The pilot allowlist is explicit and defaults to empty.
- GitHub credentials are held by the gateway, not mounted into the Hermes shell or model context.
- Read permissions cover only the pilot repository's metadata, contents, issues, pull requests,
  reviews, and comments.
- The gateway rejects write endpoints even if a caller asks for them.
- Source content is transient by default; only findings and user-approved summaries may enter the
  vault.
- Secret redaction happens before model context assembly, and findings must not echo credential
  material.
- Rate-limit, permission, missing-ref, and partial-context errors are returned explicitly.
- Repository content and issue comments may contain prompt injection; they cannot override Bip's
  system policy, tool permissions, or approval rules.
- Access requests and review outcomes can be mirrored to the existing append-only audit surface,
  but source code and full diffs are not written to audit logs.

## Pilot and rollout

The pilot targets one private personal repository. Before implementation of the gateway, the
operator must provide its GitHub App installation, repository allowlist, and read-only permission
review. Pilot validation must prove:

1. an allowlisted repository can be selected by owner/repository and ref;
2. an unallowlisted repository is rejected before GitHub access;
3. the four review modes produce bounded, evidence-backed output;
4. a proposed diff is returned without any GitHub mutation; and
5. missing credentials, rate limits, large files, binary files, and detected secrets fail closed.

Broader repository access, issue mutation, PR creation, or automated patch application each
requires its own issue and threat-model review.

## Implementation deliverables for issue #17

- ADR-006 recording this read-only gateway decision and the future-write boundary.
- `docs/GITHUB_REVIEW.md` describing the pilot workflow, review modes, findings contract, and
  privacy limits.
- Links from `README.md`, `docs/MCP.md`, and `docs/SECURITY.md` so operators see the contract.
- A focused validator and test that assert the allowlist/read-only wording and that the current
  Compose stack has no GitHub write service or GitHub credential mount.
- A follow-up issue for the actual GitHub MCP gateway implementation, kept separate from this
  architecture/contract issue.

## Acceptance mapping

| Issue criterion | Design response |
| --- | --- |
| End-to-end review flow | Target resolver -> read gateway -> context normalizer -> review mode -> findings/proposal. |
| Read-only inspection without mutations | One private allowlisted repository, read-only App permissions, no write tools or shell fallback. |
| Gated and auditable write path | Patch is text-only here; future Stage 5 hand requires approval and proposal/decision/execution/outcome audit. |
| Pilot before broader rollout | Explicit one-repository pilot with fail-closed validation and separate follow-up issues. |

## Revisit triggers

Create a new decision issue before expanding beyond the pilot when a second repository, GitHub
organization, webhook/event ingestion, persistent indexing, issue mutation, or pull-request
creation is required. Each expansion must retain explicit allowlisting, least privilege, private
code controls, and approval/audit evidence.
