# Stage 1: builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: final image
FROM node:20-alpine
WORKDIR /app

# Cài tini để quản lý process (tốt cho PID 1)
RUN apk add --no-cache tini

# Tạo user non-root (uid 1001, không dùng 33)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy dependencies và source
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Tạo thư mục uploads và phân quyền
RUN mkdir -p public/uploads && \
    chown -R nodejs:nodejs /app

USER nodejs

ENTRYPOINT ["/sbin/tini", "--"]

EXPOSE 3000

CMD ["node", "src/main.js"]