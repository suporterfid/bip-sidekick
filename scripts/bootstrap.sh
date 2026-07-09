#!/usr/bin/env bash
set -euo pipefail
# One-shot VPS setup: Docker (if missing) + vault git remote sanity check.

echo ">> Solo Agent Stack bootstrap"

if ! command -v docker >/dev/null 2>&1; then
  echo ">> Installing Docker..."
  curl -fsSL https://get.docker.com | sh
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "!! Docker Compose plugin not found. Install it, then re-run." >&2
  exit 1
fi

if [ ! -f .env ]; then
  echo "!! No .env found. Run: cp .env.example .env  and fill it in." >&2
  exit 1
fi

# shellcheck disable=SC1091
set -a; . ./.env; set +a
[ -n "${VAULT_GIT_REMOTE:-}" ] || echo ">> (note) VAULT_GIT_REMOTE empty — vault-sync will be a no-op until set."

echo ">> OK. Next: make up-core   (then use it a week before adding stages 3–4)"
