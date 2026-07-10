# GitHub Backlog Workflow

This repository uses GitHub Issues as the canonical backlog for future topics. The preferred
shape is the GitHub Project
[`Bip Sidekick Backlog`](https://github.com/users/suporterfid/projects/3), but the
repository must still work well even before project scopes are granted to the local GitHub
CLI token.

## Source of truth

- GitHub Issues are the durable backlog.
- `vault/BACKLOG.md` is the short working shortlist for the human + agent loop.
- `docs/ROADMAP.md` remains the staged product sequence and should point at backlog issues,
  not replace them.

## Capture flow

1. Create a new issue with the `Backlog item` issue form.
2. Leave the default labels `backlog` and `needs-triage`.
3. During triage, replace `needs-triage` with the right `priority:*`, `effort:*`, and
   `area:*` labels.
4. Add `next-up` only to the very small set of topics that are realistic candidates for the
   next implementation pass.

## Label taxonomy

| Label | Purpose |
|---|---|
| `backlog` | Long-lived planned work and future topics |
| `needs-triage` | Newly captured item that still needs sorting |
| `next-up` | Small near-term shortlist |
| `priority:high` / `priority:medium` / `priority:low` | Relative importance |
| `effort:s` / `effort:m` / `effort:l` | Rough size |
| `area:runtime` / `area:briefing` / `area:governance` / `area:integrations` / `area:docs` | Primary system surface |

## Current seeded backlog

The repository already has roadmap-backed issues. The setup script normalizes them with the
label taxonomy above instead of creating duplicates.

## GitHub Project bootstrap

The local `gh` session needs the `project` scope to create or manage a Project. If that
scope is missing, refresh the token before running the bootstrapper:

```powershell
gh auth refresh -s read:project -s project
powershell -ExecutionPolicy Bypass -File .\scripts\setup-github-backlog.ps1
```

The script creates or verifies `Bip Sidekick Backlog`, links `suporterfid/bip-sidekick`,
normalizes backlog labels, creates the project fields, and adds open `backlog` issues.

Project fields:

- `Priority` as `SINGLE_SELECT` with `High`, `Medium`, `Low`
- `Area` as `SINGLE_SELECT` with `Runtime`, `Briefing`, `Governance`, `Integrations`, `Docs`
- `Effort` as `SINGLE_SELECT` with `S`, `M`, `L`
- `Target` as `DATE`

Suggested saved views:

- `Inbox`: filter `label:"needs-triage"`
- `Backlog`: filter `label:"backlog" -label:"next-up"`
- `Next`: filter `label:"next-up"`

The CLI manages the project, fields, repository link, project README, and items. Saved
views are still easiest to finalize in the GitHub web UI when view creation is unavailable
through the local CLI/API surface.
