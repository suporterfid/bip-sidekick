#!/usr/bin/env sh
set -eu

test -f services/hermes/Dockerfile
test -f services/hermes/entrypoint.sh
test -f services/hermes/templates/config.yaml
test -f services/hermes/templates/BIP.md
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

grep -q 'cp /opt/bip/templates/BIP.md /vault/BIP.md' services/hermes/entrypoint.sh
grep -q 'cat /vault/BIP.md' services/hermes/entrypoint.sh
grep -q 'SOUL.md - generated for Hermes runtime' services/hermes/entrypoint.sh
grep -q 'Edit /vault/BIP.md, not this file' services/hermes/entrypoint.sh
grep -q 'Hermes memories are optional scratch and do not replace /vault' services/hermes/entrypoint.sh

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
