FROM nousresearch/hermes-agent:latest

USER root
RUN mkdir -p /opt/bip/templates/cron /opt/bip/hooks

COPY templates/ /opt/bip/templates/
COPY hooks/ /opt/bip/hooks/
COPY entrypoint.sh /opt/bip/entrypoint.sh

RUN chmod +x /opt/bip/entrypoint.sh /opt/bip/hooks/audit-jsonl.py

ENTRYPOINT ["/opt/bip/entrypoint.sh"]
CMD ["gateway", "run"]
