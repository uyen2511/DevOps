FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine
WORKDIR /app

RUN apk add --no-cache shadow && \
	usermod -u 33 node && \
	groupmod -g 33 node

COPY --from=builder /app/node_modules ./node_modules
COPY . .

USER node

EXPOSE 3000

CMD ["npm", "start"]
