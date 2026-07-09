FROM node:22-alpine
RUN apk add --no-cache tini
WORKDIR /app
ENTRYPOINT ["/sbin/tini","--"]
CMD ["node","-e","console.log('telegram-bridge superseded by services/hermes'); setInterval(()=>{},1e9)"]
