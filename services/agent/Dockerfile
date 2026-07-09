# Utility image for vault-sync.
# The Hermes runtime lives in services/hermes; this image only provides git + shell tools.
FROM node:22-alpine
RUN apk add --no-cache git openssh-client bash tini
WORKDIR /app
ENTRYPOINT ["/sbin/tini","--"]
CMD ["bash","-lc","echo 'vault-sync utility image ready'; sleep infinity"]
