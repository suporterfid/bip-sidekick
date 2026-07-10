# telegram-bridge - superseded runtime stub

> Superseded by `services/hermes/` in the Hermes-native runtime. This directory is kept
> only as historical context while the migration settles.

The original plan used this service as the Telegram command inbox and approval gate.
Hermes now owns Telegram integration and manual approvals.

This directory is intentionally inactive in Compose. Telegram behavior should be documented
or configured through `services/hermes/`, `docs/ARCHITECTURE.md`, and `docs/SECURITY.md`.
