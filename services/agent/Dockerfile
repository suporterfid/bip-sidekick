# Minimal runtime for the agent + the git-sync sidecar (shared image).
# Replace/extend with your actual Claude Code install for the agent service.
FROM node:22-alpine
RUN apk add --no-cache git openssh-client bash tini
WORKDIR /app
# TODO: install Claude Code CLI here for the `agent` service.
# The `vault-sync` service only needs git + bash (already present).
ENTRYPOINT ["/sbin/tini","--"]
CMD ["bash","-lc","echo 'agent image ready — install Claude Code + HTTP shim (see README)'; sleep infinity"]
