# hermes - Bip runtime

This image wraps the official Hermes Agent container for Bip Sidekick.

Runtime state lives in `/opt/data`. Bip's human-readable memory and identity live in
`/vault`. On startup the entrypoint generates `/opt/data/SOUL.md` from `/vault/BIP.md`.

The service runs `hermes gateway run` and keeps dashboard/API ports unpublished by
default. Shell access is container-scoped; the Docker socket and host filesystem are not
mounted.
