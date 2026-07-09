#!/usr/bin/env sh
set -eu

HERMES_HOME="${HERMES_HOME:-/opt/data}"
BRIEF_CRON="${BRIEF_CRON:-0 6 * * *}"
export HERMES_HOME

mkdir -p "$HERMES_HOME" "$HERMES_HOME/cron" "$HERMES_HOME/cron/output" "$HERMES_HOME/logs" /vault/daily /audit

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

if [ -n "${HERMES_HOME:-}" ] && id hermes >/dev/null 2>&1; then
  find "$HERMES_HOME" ! -user hermes -exec chown hermes: {} +
fi

brief_prompt="$(cat "$HERMES_HOME/cron/bip-daily-brief.md")"
existing_brief_jobs="$(
  hermes cron list --all 2>/dev/null |
    awk '
      $1 ~ /^[0-9a-f][0-9a-f]*$/ { job_id = $1 }
      $1 == "Name:" && $2 == "bip-daily-brief" { print job_id }
    '
)"

for job_id in $existing_brief_jobs; do
  hermes cron remove "$job_id"
done

hermes cron create "$BRIEF_CRON" "$brief_prompt" \
  --name bip-daily-brief \
  --deliver telegram \
  --workdir /vault
cron_jobs="$(hermes cron list --all)"
printf '%s\n' "$cron_jobs" | grep -q 'Name:      bip-daily-brief'

if [ -n "${TELEGRAM_CHAT_ID:-}" ] && [ -z "${TELEGRAM_ALLOWED_USERS:-}" ]; then
  export TELEGRAM_ALLOWED_USERS="$TELEGRAM_CHAT_ID"
fi

exec hermes "$@"
