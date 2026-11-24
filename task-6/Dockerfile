# Build stage: validate and prepare the application artifact.
FROM node:24-bookworm AS build
WORKDIR /app
COPY package.json server.js ./
RUN npm run build

# Runtime stage: Alpine-based Node runtime with only the built application.
FROM node:24-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build --chown=node:node /app/dist/server.js ./server.js
USER node
EXPOSE 3000
CMD ["node", "server.js"]
