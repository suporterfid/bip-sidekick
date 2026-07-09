#!/usr/bin/env sh
set -eu

test -f services/hermes/Dockerfile
test -f services/hermes/entrypoint.sh
test -f services/hermes/templates/config.yaml
test -f services/hermes/templates/BIP.md
test -f vault/BIP.md

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

if grep -Eq 'chown[[:space:]]+-R[[:space:]]+.*HERMES_HOME' services/hermes/entrypoint.sh; then
  echo "Hermes startup must not recursively chown the persistent home on every boot" >&2
  exit 1
fi

grep -q 'chown hermes:' services/hermes/entrypoint.sh
