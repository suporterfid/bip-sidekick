#!/usr/bin/env bash
set -euo pipefail
# Stage 2 stub: register a cron job that hits the agent's brief endpoint.
echo "${BRIEF_CRON:-0 6 * * *} curl -fsS -X POST \"$AGENT_URL/run\" -d 'prompt=daily-brief' >> /var/log/brief.log 2>&1" > /etc/crontabs/root
echo "brief-engine: scheduled '${BRIEF_CRON:-0 6 * * *}' (TZ=${TZ:-UTC}). Implement /run in agent."
crond -f -l 8
