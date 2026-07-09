FROM node:22-alpine
RUN apk add --no-cache tini
WORKDIR /app
# COPY package*.json ./ && RUN npm ci --omit=dev
# COPY . .
ENTRYPOINT ["/sbin/tini","--"]
CMD ["node","-e","console.log('telegram-bridge stub — implement Stage 1 & 3 (see README)'); setInterval(()=>{},1e9)"]
