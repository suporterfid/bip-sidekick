#!/usr/bin/env python3
"""Validate Bip's Stage 1-4 read-only MCP boundary."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
MUTATION_TOOL_NAMES = {
    "send",
    "send_email",
    "send_message",
    "reply",
    "create",
    "create_event",
    "update",
    "update_event",
    "delete",
    "delete_event",
    "delete_message",
    "deploy",
    "spend",
    "charge",
    "purchase",
}


def load_compose() -> dict:
    completed = subprocess.run(
        [
            "docker",
            "compose",
            "--profile",
            "core",
            "--profile",
            "openwa",
            "config",
            "--format",
            "json",
        ],
        cwd=ROOT,
        check=True,
        text=True,
        capture_output=True,
    )
    return json.loads(completed.stdout)


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def service(data: dict, name: str, errors: list[str]) -> dict:
    value = data.get("services", {}).get(name)
    require(isinstance(value, dict), f"{name} service missing from rendered Compose config", errors)
    return value if isinstance(value, dict) else {}


def environment(value: dict) -> dict:
    env = value.get("environment") or {}
    if isinstance(env, dict):
        return env
    return {}


def network_names(value: dict) -> set[str]:
    networks = value.get("networks") or {}
    if isinstance(networks, dict):
        return set(networks)
    if isinstance(networks, list):
        return set(networks)
    return set()


def validate_compose(data: dict, errors: list[str]) -> None:
    networks = data.get("networks") or {}
    require("internal" in networks, "Compose config must define the internal network", errors)

    google = service(data, "google-mcp", errors)
    google_env = environment(google)
    require(google.get("profiles") == ["core"], "google-mcp must run in the core profile", errors)
    require(google.get("expose") == ["8081"], "google-mcp must expose only port 8081 internally", errors)
    require(not google.get("ports"), "google-mcp must not publish host ports", errors)
    require(network_names(google) == {"internal"}, "google-mcp must stay on the internal network", errors)
    require(google.get("read_only") is True, "google-mcp container must be read_only", errors)
    require(google_env.get("MCP_TRANSPORT") == "http", "google-mcp MCP_TRANSPORT must be http", errors)
    require(google_env.get("MCP_PORT") == "8081", "google-mcp MCP_PORT must be 8081", errors)
    google_scopes = google_env.get("GOOGLE_SCOPES", "")
    require("gmail.readonly" in google_scopes, "Google MCP must include Gmail readonly scope", errors)
    require("calendar.readonly" in google_scopes, "Google MCP must include Calendar readonly scope", errors)
    require("gmail.modify" not in google_scopes, "Google MCP must not include Gmail modify scope", errors)
    require("calendar.events" not in google_scopes, "Google MCP must not include Calendar write scope", errors)

    openwa = service(data, "openwa", errors)
    openwa_env = environment(openwa)
    require(openwa.get("profiles") == ["openwa"], "openwa must run only in the openwa profile", errors)
    require(openwa.get("expose") == ["3000"], "openwa must expose only port 3000 internally", errors)
    require(not openwa.get("ports"), "openwa must not publish host ports", errors)
    require(network_names(openwa) == {"internal"}, "openwa must stay on the internal network", errors)
    require(openwa_env.get("MCP_ENABLED") == "true", "OpenWA MCP must be enabled", errors)
    require(openwa_env.get("MCP_READONLY") == "true", "OpenWA MCP must stay read-only", errors)


def validate_hermes(errors: list[str]) -> None:
    config = yaml.safe_load((ROOT / "services/hermes/templates/config.yaml").read_text(encoding="utf-8"))
    servers = (config or {}).get("mcp_servers") or {}

    expected = {
        "google": "http://google-mcp:8081/mcp",
        "whatsapp": "http://openwa:3000/mcp",
    }
    for name, url in expected.items():
        server = servers.get(name) or {}
        require(server.get("enabled") is True, f"Hermes MCP server {name} must be enabled", errors)
        require(server.get("url") == url, f"Hermes MCP server {name} must use {url}", errors)
        require(
            server.get("supports_parallel_tool_calls") is False,
            f"Hermes MCP server {name} must disable parallel tool calls",
            errors,
        )
        tools = server.get("tools") or {}
        excludes = set(tools.get("exclude") or [])
        missing = sorted(MUTATION_TOOL_NAMES - excludes)
        require(not missing, f"Hermes MCP server {name} must exclude mutation tools: {', '.join(missing)}", errors)
        require(tools.get("resources") is True, f"Hermes MCP server {name} should allow resources", errors)
        require(tools.get("prompts") is False, f"Hermes MCP server {name} should disable MCP prompts", errors)


def main() -> int:
    errors: list[str] = []
    validate_compose(load_compose(), errors)
    validate_hermes(errors)

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
