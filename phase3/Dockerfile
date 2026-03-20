FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine
WORKDIR /app

RUN apk add --no-cache tini

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN mkdir -p public/uploads && \
    chown -R nodejs:nodejs /app

USER nodejs

ENTRYPOINT ["/sbin/tini", "--"]

EXPOSE 3000

CMD ["node", "src/main.js"]
