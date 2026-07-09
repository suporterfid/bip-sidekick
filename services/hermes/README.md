# hermes - Bip runtime

This image wraps the official Hermes Agent container for Bip Sidekick.

Runtime state lives in `/opt/data`. Bip's human-readable memory and identity live in
`/vault`. On startup the entrypoint generates `/opt/data/SOUL.md` from `/vault/BIP.md`.

The service runs `hermes gateway run` and keeps dashboard/API ports unpublished by
default. Shell access is container-scoped; the Docker socket and host filesystem are not
mounted.

## Daily brief cron

Startup registers a native Hermes cron job named `bip-daily-brief`. The schedule comes
from `BRIEF_CRON` and is interpreted with `TZ`; by default the brief runs at 06:00 in
`America/Sao_Paulo`. The job runs from `/vault`, delivers to Telegram, and is recreated
on restart so schedule or prompt changes take effect.

Failures surface in Hermes startup, gateway, or cron logs. The prompt remains read-only:
it may write `/vault/daily/YYYY-MM-DD.md` and send the same brief to Telegram, but cron
must not send email, WhatsApp messages, deploy, spend, delete, or mutate external systems.
