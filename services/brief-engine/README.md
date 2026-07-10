# brief-engine - superseded runtime stub

> Superseded by `services/hermes/` in the Hermes-native runtime. This directory is kept
> only as historical context while the migration settles.

The original plan used this service to schedule the daily brief through a custom cron
container. Hermes cron now owns the daily brief schedule.

This directory is intentionally inactive in Compose. Daily brief behavior should be
documented or configured through `services/hermes/templates/cron/daily-brief.md`.
