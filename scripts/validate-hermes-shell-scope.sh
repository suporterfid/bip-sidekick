#!/usr/bin/env sh
set -eu

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

docker compose --profile core --profile openwa config --format json > "$tmp"

python3 - "$tmp" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

errors = []
hermes = data.get("services", {}).get("hermes")
if not isinstance(hermes, dict):
    errors.append("hermes service missing from rendered Compose config")
else:
    if hermes.get("ports"):
        errors.append("Hermes must not publish ports by default")
    if hermes.get("privileged"):
        errors.append("Hermes must not run privileged")
    for namespace in ("pid", "ipc", "network_mode"):
        if hermes.get(namespace) == "host":
            errors.append(f"Hermes must not use host {namespace}")
    if hermes.get("devices"):
        errors.append("Hermes must not receive host devices by default")
    if hermes.get("cap_add"):
        errors.append("Hermes must not add Linux capabilities by default")

    volumes = hermes.get("volumes") or []
    expected = {
        ("/opt/data", "volume", "hermes_home"),
        ("/vault", "volume", "vault"),
        ("/audit", "volume", "audit"),
    }
    actual = set()
    for volume in volumes:
        target = volume.get("target")
        source = volume.get("source")
        kind = volume.get("type")
        actual.add((target, kind, source))
        if kind == "bind":
            errors.append(f"Hermes must not bind-mount host path {source!r} to {target!r}")
        if target in {"/var/run/docker.sock", "/run/docker.sock"} or source in {"/var/run/docker.sock", "/run/docker.sock"}:
            errors.append("Hermes must not mount the Docker socket")

    if actual != expected:
        errors.append(
            "Hermes volumes must be exactly named volumes hermes_home:/opt/data, "
            "vault:/vault, and audit:/audit"
        )

    env = hermes.get("environment") or {}
    if env.get("HERMES_HOME") != "/opt/data":
        errors.append("Hermes HERMES_HOME must stay inside /opt/data")

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    raise SystemExit(1)
PY
