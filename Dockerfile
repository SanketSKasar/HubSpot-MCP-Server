# =============================================================================
# HubSpot MCP Server - Production Docker Image
# =============================================================================
# 
# Multi-stage build for optimized, secure production container
# Implements MCP (Model Context Protocol) over HTTP with HubSpot integration
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
# Use npm install since no lock file is present
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

# Server configuration
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

# Operational configuration
ENV GRACEFUL_SHUTDOWN_TIMEOUT=10000

# Switch to non-root user for security
USER nodejs

# Expose application port (documentation only)
EXPOSE 3000

# Add health check for container orchestration
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start the MCP server
CMD ["node", "src/server.js"]