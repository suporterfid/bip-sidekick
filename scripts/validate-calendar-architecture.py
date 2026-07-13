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
        "docs/adr/ADR-005-family-calendar-architecture.md",
        ["Google Calendar", "calendar.readonly", "Cal.diy", "Stage 5"],
    )
    require_file(
        errors,
        "docs/CALENDAR.md",
        ["Read-only calendar workflow", "must not create", "manual Google Calendar action"],
    )

    compose = (ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    if "https://www.googleapis.com/auth/calendar.readonly" not in compose:
        errors.append("docker-compose.yml must retain calendar.readonly")
    if re.search(r"https://www\.googleapis\.com/auth/calendar(?!\.readonly)", compose):
        errors.append("docker-compose.yml must not grant a writable Calendar scope")
    if "cal.diy" in compose.lower():
        errors.append("docker-compose.yml must not attach Cal.diy")

    for relative_path in ("README.md", "docs/ROADMAP.md", "docs/SECURITY.md"):
        text = (ROOT / relative_path).read_text(encoding="utf-8")
        if "docs/CALENDAR.md" not in text:
            errors.append(f"{relative_path} must link docs/CALENDAR.md")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("calendar architecture validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
