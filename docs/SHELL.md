# Hermes Shell Boundary

Hermes may use shell tools only inside the `bip-hermes` container. This is a
container-scoped shell, not a host administration shell.

The default Compose deployment keeps the boundary small:

- No Docker socket mount.
- No broad host filesystem bind mount.
- No host SSH key mount.
- No published Hermes port by default.
- No privileged mode, host namespaces, extra Linux capabilities, or host devices.
- The only writable mounted surfaces are the named volumes `hermes_home:/opt/data`,
  `vault:/vault`, and `audit:/audit`.

Hermes can inspect and update intended mounted paths such as `/vault`, `/audit`, and
`/opt/data`. It cannot control Docker, restart host services, read arbitrary host paths,
or deploy from the host by default.

Dangerous interactive shell actions rely on Hermes manual approval behavior and are also
mirrored to `/audit/actions.jsonl` by the audit hooks. Cron jobs must not use shell to send, deploy, spend, delete, or mutate external systems. If a scheduled brief discovers a useful action, it should write the proposal and wait for manual approval.

Host-level deploy/send/spend operations belong in Stage 5 as separate hands with
least-privilege credentials, manual approval, and audit coverage.
