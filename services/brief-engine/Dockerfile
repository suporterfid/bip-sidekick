FROM alpine:3.20
RUN apk add --no-cache bash curl tzdata tini
WORKDIR /app
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/sbin/tini","--"]
CMD ["/app/entrypoint.sh"]
