# Dockerfile.backend

FROM node:20-alpine AS builder
WORKDIR /app

# Copy deps and set up them
COPY package*.json ./
RUN npm ci

# Copy rest code
COPY . .
# Create /dist folder
RUN npm run build

# --- STAGE 2: (RUNTIME STAGE) ---

FROM node:20-alpine AS runtime

WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Change owner of the working directory to our new user
RUN chown -R appuser:appgroup /app

USER appuser

# Copy only production dependencies from the builder stage
# We install them again in the runtime image to exclude devDependencies
COPY --from=builder /app/package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy the built files from the builder stage (dist/<app>/server + browser)
# Make sure the /dist path is correct
COPY --from=builder /app/dist ./dist

# Environment variables (env vars) will be provided via `docker run` or docker-compose
# They will be available in the Node.js process through process.env.*
# (e.g., process.env.API_ENDPOINT, process.env.FEATURE_FLAGS)

EXPOSE 3000

# Add HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl --fail http://localhost:3000 || exit 1

# Node.js automatically process SIGTERM (graceful shutdown)
CMD [ "npm", "start" ]
