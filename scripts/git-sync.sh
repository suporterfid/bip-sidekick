#!/usr/bin/env bash
set -euo pipefail
# Periodically sync the vault volume with a PRIVATE git remote so Obsidian on your
# devices stays current. Last-write-wins; keep agent writes scoped to daily notes.
cd /vault
INTERVAL="${GIT_SYNC_INTERVAL:-300}"
REMOTE="${VAULT_GIT_REMOTE:-}"
BRANCH="${VAULT_GIT_BRANCH:-main}"

if [ -z "$REMOTE" ]; then
  echo "git-sync: VAULT_GIT_REMOTE unset — idling."; exec sleep infinity
fi

if [ ! -d .git ]; then
  git init -q && git remote add origin "$REMOTE" && git checkout -q -b "$BRANCH" || true
  git fetch -q origin "$BRANCH" 2>/dev/null && git reset -q --hard "origin/$BRANCH" || true
fi

while true; do
  git add -A
  git commit -q -m "vault sync $(date -u +%FT%TZ)" 2>/dev/null || true
  git pull -q --rebase origin "$BRANCH" 2>/dev/null || true
  git push -q origin "$BRANCH" 2>/dev/null || echo "git-sync: push failed (check creds/remote)"
  sleep "$INTERVAL"
done
