#!/usr/bin/env sh
set -eu

test -f services/hermes/Dockerfile
test -f services/hermes/entrypoint.sh
test -f services/hermes/templates/config.yaml
test -f services/hermes/templates/BIP.md
test -f services/hermes/hooks/audit-jsonl.py
test -f docs/AUDIT.md
test -f docs/SHELL.md
test -f docs/MCP.md
test -f docs/BILL_REMINDERS.md
test -f docs/adr/ADR-004-hermes-native-runtime.md
test -f scripts/validate-readonly-mcp.py
test -f scripts/validate-bill-reminders.py
test -f vault/BIP.md
test -f vault/CLAUDE.md

cr="$(printf '\r')"
for script in $(git ls-files '*.sh'); do
  if grep -q "$cr" "$script"; then
    echo "$script must use LF line endings for Linux containers" >&2
    exit 1
  fi
done

bash -n services/hermes/entrypoint.sh
bash -n scripts/validate-hermes-migration.sh
bash -n scripts/validate-hermes-shell-scope.sh
python3 -m py_compile services/hermes/hooks/audit-jsonl.py
python3 -m py_compile scripts/validate-readonly-mcp.py
python3 -m py_compile scripts/validate-bill-reminders.py
sh scripts/validate-hermes-shell-scope.sh
python3 scripts/validate-readonly-mcp.py
python3 scripts/validate-bill-reminders.py

grep -q '^  hermes:$' docker-compose.yml
grep -q '^    profiles: \["core"\]' docker-compose.yml
grep -q '^    build: ./services/hermes' docker-compose.yml
grep -q '^    container_name: bip-hermes' docker-compose.yml
grep -q 'command: \["gateway", "run"\]' docker-compose.yml
grep -q 'depends_on: \[google-mcp\]' docker-compose.yml
grep -q '^  vault-sync:$' docker-compose.yml
grep -q '^  google-mcp:$' docker-compose.yml

if grep -Eq '^  (agent|telegram-bridge|brief-engine):$' docker-compose.yml; then
  echo "superseded runtime services must not be active in docker-compose.yml" >&2
  exit 1
fi

grep -A2 '^up-core:' Makefile | grep -q -- '--profile core up -d --build' || {
  echo "make up-core must use the core profile" >&2
  exit 1
}

grep -A2 '^up-gate:' Makefile | grep -q -- '--profile core up -d --build hermes' || {
  echo "make up-gate must refresh the Hermes service" >&2
  exit 1
}

grep -q 'Usage: make logs SVC=hermes' Makefile || {
  echo "make logs must document SVC=hermes" >&2
  exit 1
}

grep -A2 '^audit:' Makefile | grep -q '/audit/actions.jsonl' || {
  echo "make audit must tail /audit/actions.jsonl" >&2
  exit 1
}

grep -q 'TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN}' docker-compose.yml
grep -q 'TELEGRAM_CHAT_ID: ${TELEGRAM_CHAT_ID}' docker-compose.yml
grep -q 'TELEGRAM_ALLOWED_USERS: ${TELEGRAM_ALLOWED_USERS:-}' docker-compose.yml
grep -q 'TELEGRAM_CHAT_ID=            # compatibility input' .env.example
grep -q 'TELEGRAM_ALLOWED_USERS=      # optional; defaults to TELEGRAM_CHAT_ID when empty' .env.example

grep -q 'export TELEGRAM_ALLOWED_USERS="$TELEGRAM_CHAT_ID"' services/hermes/entrypoint.sh || {
  echo "TELEGRAM_CHAT_ID must map to TELEGRAM_ALLOWED_USERS when the allowlist is empty" >&2
  exit 1
}

grep -q 'mcp_reload_confirm: true' services/hermes/templates/config.yaml
grep -q 'destructive_slash_confirm: true' services/hermes/templates/config.yaml
grep -q 'Approval voice: `bip? - <action>? \[Sim\] \[Nao\]`.' vault/BIP.md
grep -q 'Approval voice: `bip? - <action>? \[Sim\] \[Nao\]`.' services/hermes/templates/BIP.md

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

grep -q 'hooks:' services/hermes/templates/config.yaml
grep -q 'pre_approval_request:' services/hermes/templates/config.yaml
grep -q 'post_approval_response:' services/hermes/templates/config.yaml
grep -q 'post_tool_call:' services/hermes/templates/config.yaml
grep -q 'command: /opt/bip/hooks/audit-jsonl.py' services/hermes/templates/config.yaml
grep -q 'COPY hooks/ /opt/bip/hooks/' services/hermes/Dockerfile
grep -q 'chmod +x /opt/bip/entrypoint.sh /opt/bip/hooks/audit-jsonl.py' services/hermes/Dockerfile
grep -q 'touch /audit/actions.jsonl' services/hermes/entrypoint.sh
grep -q 'chown hermes: /audit /audit/actions.jsonl' services/hermes/entrypoint.sh
grep -q 'chmod 700 /audit' services/hermes/entrypoint.sh
grep -q 'chmod 600 /audit/actions.jsonl' services/hermes/entrypoint.sh
grep -q 'HERMES_HOME", "/opt/data"' services/hermes/entrypoint.sh
grep -q 'yaml.safe_load' services/hermes/entrypoint.sh
grep -q 'post_tool_call' services/hermes/entrypoint.sh
grep -q '_record_approval(event, command)' services/hermes/entrypoint.sh
grep -q 'proposal' services/hermes/hooks/audit-jsonl.py
grep -q 'decision' services/hermes/hooks/audit-jsonl.py
grep -q 'execution' services/hermes/hooks/audit-jsonl.py
grep -q 'approval_message_id' services/hermes/hooks/audit-jsonl.py
grep -q 'unsupported_fields' docs/AUDIT.md
grep -q 'approval_message_id' docs/AUDIT.md
grep -q 'make audit' docs/AUDIT.md
grep -q 'actions.jsonl' docs/SECURITY.md
grep -q 'container-scoped shell' docs/SHELL.md
grep -q 'No Docker socket mount' docs/SHELL.md
grep -q 'No broad host filesystem bind mount' docs/SHELL.md
grep -q 'Cron jobs must not use shell to send, deploy, spend, delete, or mutate' docs/SHELL.md
grep -q 'manual approval' docs/SHELL.md
grep -q 'docs/SHELL.md' docs/SECURITY.md
grep -q 'docs/SHELL.md' services/hermes/README.md
grep -q 'ADR-004 records the runtime decision' README.md
grep -q 'bash scripts/validate-hermes-migration.sh' README.md
grep -q 'docker compose --profile core --profile openwa config' README.md
grep -q 'docs/adr/ADR-004-hermes-native-runtime.md' README.md
grep -q 'are historical' docs/ARCHITECTURE.md
grep -q 'runtime stubs' docs/ARCHITECTURE.md
grep -q 'owns the gateway, cron, MCP session, approval, and shell surfaces' docs/ARCHITECTURE.md
grep -q 'Telegram and Approval Flow' docs/ARCHITECTURE.md
grep -q 'MCP Read-only Flow' docs/ARCHITECTURE.md
grep -q 'docs/MCP.md' README.md
grep -q 'docs/MCP.md' docs/ARCHITECTURE.md
grep -q 'docs/MCP.md' docs/SECURITY.md
grep -q 'read-only MCP contract' docs/MCP.md
grep -q 'Shell access is container-scoped inside `bip-hermes`' docs/ARCHITECTURE.md
grep -q 'The current repository shape is Hermes-native' docs/ROADMAP.md
grep -q 'Keep the old `agent`, `telegram-bridge`, and `brief-engine` runtime paths inactive' docs/ROADMAP.md
grep -q 'Runtime Boundaries' docs/SECURITY.md
grep -q 'Audit Caveats' docs/SECURITY.md
grep -q 'Use Hermes as Bip.*native runtime' docs/adr/ADR-004-hermes-native-runtime.md
grep -q 'Docs, Makefile targets, and validation scripts should describe Hermes as the current' docs/adr/ADR-004-hermes-native-runtime.md
grep -q 'primary command, approval, or scheduling path' docs/adr/ADR-004-hermes-native-runtime.md
grep -q 'Do not add agent command handling here' services/agent/README.md
grep -q 'intentionally inactive in Compose' services/telegram-bridge/README.md
grep -q 'intentionally inactive in Compose' services/brief-engine/README.md

grep -q 'cp /opt/bip/templates/BIP.md /vault/BIP.md' services/hermes/entrypoint.sh
grep -q 'cat /vault/BIP.md' services/hermes/entrypoint.sh
grep -q 'SOUL.md - generated for Hermes runtime' services/hermes/entrypoint.sh
grep -q 'Edit /vault/BIP.md, not this file' services/hermes/entrypoint.sh
grep -q 'Hermes memories are optional scratch and do not replace /vault' services/hermes/entrypoint.sh
grep -q 'BRIEF_CRON="${BRIEF_CRON:-0 6 \* \* \*}"' services/hermes/entrypoint.sh
grep -q '"$HERMES_HOME/cron/output"' services/hermes/entrypoint.sh
grep -q 'hermes cron remove "$job_id"' services/hermes/entrypoint.sh
grep -q 'hermes cron create "$BRIEF_CRON"' services/hermes/entrypoint.sh
grep -q 'cron_jobs="$(hermes cron list --all)"' services/hermes/entrypoint.sh
grep -q 'printf.*cron_jobs' services/hermes/entrypoint.sh
grep -q 'Name:      bip-daily-brief' services/hermes/entrypoint.sh
grep -q -- '--name bip-daily-brief' services/hermes/entrypoint.sh
grep -q -- '--deliver telegram' services/hermes/entrypoint.sh
grep -q -- '--workdir /vault' services/hermes/entrypoint.sh
awk '
  /find "\$HERMES_HOME" ! -user hermes/ { chown_line = NR }
  /hermes cron create "\$BRIEF_CRON"/ { cron_line = NR }
  END { exit !(chown_line && cron_line && chown_line < cron_line) }
' services/hermes/entrypoint.sh
grep -q 'TZ: ${TZ:-America/Sao_Paulo}' docker-compose.yml
grep -q 'BRIEF_CRON: ${BRIEF_CRON:-0 6 \* \* \*}' docker-compose.yml
grep -q 'Write the brief to `/vault/daily/YYYY-MM-DD.md`' services/hermes/templates/cron/daily-brief.md
grep -q 'send the same brief to Telegram' services/hermes/templates/cron/daily-brief.md
grep -q 'Do not send email, send WhatsApp messages, deploy, spend money, delete data, or mutate' services/hermes/templates/cron/daily-brief.md
grep -q 'Startup registers a native Hermes cron job named `bip-daily-brief`' services/hermes/README.md
grep -q 'The schedule comes' services/hermes/README.md
grep -q 'from `BRIEF_CRON` and is interpreted with `TZ`' services/hermes/README.md

grep -q 'provider-neutral operating instructions now live in `BIP.md`' vault/CLAUDE.md
grep -q 'source of truth for Bip identity' vault/CLAUDE.md
grep -q 'provider-neutral identity' docs/ARCHITECTURE.md
grep -q 'source. `vault/CLAUDE.md` remains as a compatibility pointer' docs/ARCHITECTURE.md
grep -q 'generates runtime' docs/ARCHITECTURE.md

if grep -Eq 'chown[[:space:]]+-R[[:space:]]+.*HERMES_HOME' services/hermes/entrypoint.sh; then
  echo "Hermes startup must not recursively chown the persistent home on every boot" >&2
  exit 1
fi

grep -q 'chown hermes:' services/hermes/entrypoint.sh
