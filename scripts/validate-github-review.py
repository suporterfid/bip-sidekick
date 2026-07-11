from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]


def require_file(errors, relative_path, needles):
    path = ROOT / relative_path
    if not path.is_file():
        errors.append(f"missing {relative_path}")
        return
    text = path.read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            errors.append(f"{relative_path} must contain {needle!r}")


def main():
    errors = []
    require_file(
        errors,
        "docs/adr/ADR-006-github-review-workflow.md",
        ["read-only", "allowlist", "Stage 5", "private"],
    )
    require_file(
        errors,
        "docs/GITHUB_REVIEW.md",
        ["Pilot workflow", "must not", "patch proposal", "untrusted"],
    )

    compose = (ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    mcp = (ROOT / "mcp/.mcp.json").read_text(encoding="utf-8")
    if re.search(r"^\s+github-mcp:", compose, re.MULTILINE):
        errors.append("docker-compose.yml must not attach a GitHub gateway in this issue")
    if re.search(r"GITHUB_(?:TOKEN|APP_ID|APP_PRIVATE_KEY|INSTALLATION_ID)", compose):
        errors.append("docker-compose.yml must not mount GitHub credentials")
    if re.search(r'"github"\s*:', mcp, re.IGNORECASE):
        errors.append("mcp/.mcp.json must not attach a GitHub server in this issue")

    for relative_path in ("README.md", "docs/MCP.md", "docs/SECURITY.md"):
        text = (ROOT / relative_path).read_text(encoding="utf-8")
        if "docs/GITHUB_REVIEW.md" not in text:
            errors.append(f"{relative_path} must link docs/GITHUB_REVIEW.md")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("github review contract validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
