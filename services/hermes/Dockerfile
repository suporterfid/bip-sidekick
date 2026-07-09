FROM nousresearch/hermes-agent:latest

USER root
RUN mkdir -p /opt/bip/templates/cron

COPY templates/ /opt/bip/templates/
COPY entrypoint.sh /opt/bip/entrypoint.sh

RUN chmod +x /opt/bip/entrypoint.sh

ENTRYPOINT ["/opt/bip/entrypoint.sh"]
CMD ["gateway", "run"]
