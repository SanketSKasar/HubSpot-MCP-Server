# =============================================================================
# HubSpot MCP Server - Production Docker Image
# =============================================================================
# 
# Optimized, secure production container for MCP (Model Context Protocol) 
# implementation with HubSpot integration and configurable ports
# 
# Security features: Non-root execution, minimal base image, hardened configuration
# 
# =============================================================================

# Build stage
FROM node:20.12.0-alpine3.18 AS builder

# Set working directory
WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./

# Install only production dependencies
RUN npm install --only=production --no-audit --no-fund

# Production stage
FROM node:20.12.0-alpine3.18 AS production

# Install security updates and minimal required packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        dumb-init \
        curl && \
    rm -rf /var/cache/apk/*

# Create non-root user for security
RUN adduser -S -D -H -u 1001 -s /sbin/nologin nodejs

# Set working directory
WORKDIR /app

# Copy dependencies from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application source code
COPY --chown=nodejs:nodejs src/ ./src/
COPY --chown=nodejs:nodejs package*.json ./

# Set production environment variables with secure defaults
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=512"

# Transport configuration - PORT is configurable via build args or runtime
ENV TRANSPORT=http
ENV PORT=3000
ENV HOST=0.0.0.0

# Application metadata
ENV APP_NAME=hubspot-mcp-server
ENV APP_VERSION=1.0.0

# HubSpot API configuration
ENV HUBSPOT_API_URL=https://api.hubapi.com

# Security configuration
ENV CORS_ORIGIN=localhost
ENV MAX_REQUEST_SIZE=10485760

# Session management
ENV MAX_CONNECTIONS=100
ENV SESSION_TIMEOUT=3600

# Rate limiting
ENV RATE_LIMIT_TOOLS=60
ENV RATE_LIMIT_RESOURCES=30
ENV MAX_CONCURRENT_REQUESTS=10

# Connection configuration
ENV CONNECTION_TIMEOUT=30000
ENV GRACEFUL_SHUTDOWN_TIMEOUT=10000

# Build argument for configurable port (can be overridden at build time)
ARG EXPOSE_PORT=3000

# Switch to non-root user for security
USER nodejs

# Expose configurable application port (can be set via build arg or environment)
EXPOSE ${EXPOSE_PORT}

# Add health check for container orchestration with configurable port
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT:-3000}/health || exit 1

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start the MCP server in production mode
CMD ["node", "src/server.js"]