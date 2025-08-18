# HubSpot MCP Server

[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-Available-brightgreen?logo=github)](https://github.com/SanketSKasar/HubSpot-MCP-Server/pkgs/container/hubspot-mcp-server)
[![Docker Hub](https://img.shields.io/badge/docker.hub-Available-brightgreen?logo=docker)](https://hub.docker.com/r/sanketskasar/hubspot-mcp-server)
[![Docker Pulls](https://img.shields.io/docker/pulls/sanketskasar/hubspot-mcp-server?logo=docker)](https://hub.docker.com/r/sanketskasar/hubspot-mcp-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-20.12.0-green?logo=node.js)](https://nodejs.org/)
[![Docker](https://img.shields.io/badge/Docker-Multi--Arch-blue?logo=docker)](https://docker.com/)
[![MCP Protocol](https://img.shields.io/badge/MCP-21%20Endpoints-purple)](https://modelcontextprotocol.io/)

🚀 A complete **Model Context Protocol (MCP)** server for HubSpot CRM integration, implementing all 21 MCP protocol endpoints with multi-transport support (HTTP, Streamable HTTP, STDIO) and flexible port configuration.

## ✨ Features

- **Complete MCP Protocol**: All 21 endpoints (initialize, tools, resources, prompts, notifications, logging)
- **Multi-Transport Support**: HTTP JSON-RPC, Streamable HTTP (SSE), STDIO for process-based communication
- **Comprehensive HubSpot Integration**: 15+ tools for contacts, companies, deals with full CRUD operations
- **Session Management**: UUID-based sessions with timeout and rate limiting
- **Production Ready**: Health checks, metrics, structured logging, graceful shutdown
- **Security Hardened**: OWASP compliance, non-root execution, security headers
- **Multi-Architecture**: Docker images for AMD64 and ARM64 platforms
- **Flexible Port Configuration**: Configurable ports via build args and runtime environment variables
- **Advanced Session Management**: Cookie and header-based session persistence for HTTP requests

## 📦 Available Images

| Registry | Image | Command |
|----------|-------|---------|
| **GitHub Container Registry** | `ghcr.io/sanketskasar/hubspot-mcp-server:latest` | `docker pull ghcr.io/sanketskasar/hubspot-mcp-server:latest` |
| **Docker Hub** | `sanketskasar/hubspot-mcp-server:latest` | `docker pull sanketskasar/hubspot-mcp-server:latest` |

## 🚀 Quick Start

### Prerequisites
- Docker installed on your system
- HubSpot Private App Access Token ([Setup Guide](#hubspot-setup))

### 1. Run Container

**GitHub Container Registry (Recommended):**
```bash
docker run -d \
  --name hubspot-mcp-server \
  -p 3000:3000 \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here \
  -e TRANSPORT=http \
  --restart unless-stopped \
  ghcr.io/sanketskasar/hubspot-mcp-server:latest
```

**Docker Hub:**
```bash
docker run -d \
  --name hubspot-mcp-server \
  -p 3000:3000 \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here \
  -e TRANSPORT=http \
  --restart unless-stopped \
  sanketskasar/hubspot-mcp-server:latest
```

**Custom Port Configuration:**
```bash
# Use custom host port (e.g., 8080) while keeping container port as 3000
docker run -d \
  --name hubspot-mcp-server \
  -p 8080:3000 \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here \
  --restart unless-stopped \
  ghcr.io/sanketskasar/hubspot-mcp-server:latest

# Use custom container port (requires rebuild)
docker build --build-arg EXPOSE_PORT=8080 -t hubspot-mcp-server:custom .
docker run -d \
  --name hubspot-mcp-server \
  -p 8080:8080 \
  -e PORT=8080 \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here \
  hubspot-mcp-server:custom
```

### 2. Verify Installation
```bash
# Check health
curl http://localhost:3000/health

# Expected response:
# {"status":"healthy","uptime":...,"version":"1.0.0","sessions":0}

# Check MCP capabilities
curl -X POST http://localhost:3000/mcp/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"test"}}}'
```

## 🔧 Transport Protocols

### HTTP Transport (Default)
Standard JSON-RPC 2.0 over HTTP:
```bash
docker run -d -p 3000:3000 \
  -e TRANSPORT=http \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token \
  ghcr.io/sanketskasar/hubspot-mcp-server:latest
```

### Streamable HTTP Transport 
Server-sent events for real-time updates:
```bash
docker run -d -p 3000:3000 \
  -e TRANSPORT=streamable-http \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token \
  ghcr.io/sanketskasar/hubspot-mcp-server:latest

# Connect to stream
curl -N -H "Accept: text/event-stream" http://localhost:3000/mcp/stream
```

### STDIO Transport
Process-based communication:
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize"}' | \
docker run --rm -i \
  -e TRANSPORT=stdio \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token \
  ghcr.io/sanketskasar/hubspot-mcp-server:latest
```

## ⚙️ Configuration

### Environment Variables

```bash
# Required Configuration
HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here

# Transport Configuration
TRANSPORT=http                    # http, streamable-http, stdio
PORT=3000
HOST=0.0.0.0

# Session Management
MAX_CONNECTIONS=100
SESSION_TIMEOUT=3600              # seconds

# Rate Limiting
RATE_LIMIT_TOOLS=60              # requests per minute
RATE_LIMIT_RESOURCES=30          # requests per minute  
MAX_CONCURRENT_REQUESTS=10       # per session

# Security
CORS_ORIGIN=*                    # "*", specific domain, or comma-separated
MAX_REQUEST_SIZE=10485760        # 10MB

# Operational
LOG_LEVEL=info                   # debug, info, warn, error
CONNECTION_TIMEOUT=30000         # milliseconds
GRACEFUL_SHUTDOWN_TIMEOUT=10000  # milliseconds
```

### Docker Compose

**Basic Configuration:**
```yaml
version: '3.8'
services:
  hubspot-mcp-server:
    image: ghcr.io/sanketskasar/hubspot-mcp-server:latest
    container_name: hubspot-mcp-server
    ports:
      - "${HOST_PORT:-3000}:${CONTAINER_PORT:-3000}"
    environment:
      HUBSPOT_PRIVATE_APP_ACCESS_TOKEN: ${HUBSPOT_PRIVATE_APP_ACCESS_TOKEN}
      PORT: ${CONTAINER_PORT:-3000}
      TRANSPORT: http
      MAX_CONNECTIONS: 100
      SESSION_TIMEOUT: 3600
      RATE_LIMIT_TOOLS: 60
      RATE_LIMIT_RESOURCES: 30
      LOG_LEVEL: info
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${CONTAINER_PORT:-3000}/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Custom Port Configuration:**
```bash
# Run on custom ports
HOST_PORT=8080 CONTAINER_PORT=3000 docker-compose up -d

# Or set in .env file:
# HOST_PORT=8080
# CONTAINER_PORT=3000
```

## 🔧 Session Management

The server provides **advanced session management** for HTTP requests to maintain state across multiple API calls:

### Session Creation
Sessions are automatically created on the first request and tracked via:
- **X-Session-ID Header**: Primary method for API clients
- **mcp-session Cookie**: Browser-friendly session persistence  
- **Request Body Parameter**: Alternative session identification

### Session Persistence Examples

**Using Headers (Recommended for API clients):**
```bash
# 1. Initialize and get session ID
response=$(curl -s -i -X POST http://localhost:3000/mcp/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {...}}')

# Extract session ID from X-Session-ID header
session_id=$(echo "$response" | grep -i "x-session-id" | cut -d' ' -f2 | tr -d '\r')

# 2. Use session ID in subsequent requests
curl -X POST http://localhost:3000/mcp/ \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: $session_id" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}'
```

**Using Cookies (Browser-compatible):**
```bash
# Save cookies and reuse them
curl -c cookies.txt -X POST http://localhost:3000/mcp/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {...}}'

# Subsequent requests with cookies
curl -b cookies.txt -X POST http://localhost:3000/mcp/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "resources/list", "params": {}}'
```

### Session Features
- **Automatic Creation**: Sessions created transparently on first request
- **Multiple Persistence Methods**: Headers, cookies, and body parameters
- **Configurable Timeout**: Sessions expire after `SESSION_TIMEOUT` seconds
- **Reconnection Support**: SSE transport allows session reconnection
- **Rate Limiting**: Per-session rate limits for tools and resources
- **Security**: HttpOnly cookies, SameSite protection, optional Secure flag

## 🔑 HubSpot Setup

### Step 1: Create Private App
1. Go to **HubSpot Settings** → **Integrations** → **Private Apps**
2. Click **"Create a private app"**
3. Configure required scopes:

| Scope | Purpose |
|-------|---------|
| `crm.objects.contacts.read` | Read contact information |
| `crm.objects.contacts.write` | Create and update contacts |
| `crm.objects.companies.read` | Read company information |  
| `crm.objects.companies.write` | Create and update companies |
| `crm.objects.deals.read` | Read deal information |
| `crm.objects.deals.write` | Create and update deals |
| `crm.objects.owners.read` | Read owner/sales rep information |

### Step 2: Generate Token
1. Go to **Auth** tab
2. Copy the **Access Token** (starts with `pat-...`)
3. **⚠️ Keep this token secure!**

### Step 3: Test Token
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     "https://api.hubapi.com/crm/v3/objects/contacts?limit=1"
```

## 🛠️ Available Tools

The server implements **15+ HubSpot CRM tools** through the MCP protocol:

### Contact Management
| Tool | Description | Parameters |
|------|-------------|------------|
| `get_contacts` | Retrieve contacts with pagination | `limit`, `properties`, `after` |
| `create_contact` | Create new contact | `email` (required), other properties |
| `update_contact` | Update existing contact | `id`, `properties` |
| `search_contacts` | Search contacts by query | `query`, `properties`, `limit` |
| `get_contact_by_email` | Get contact by email | `email` |

### Company Management
| Tool | Description | Parameters |
|------|-------------|------------|
| `get_companies` | Retrieve companies with pagination | `limit`, `properties`, `after` |
| `create_company` | Create new company | `name` (required), other properties |
| `update_company` | Update existing company | `id`, `properties` |
| `search_companies` | Search companies by query | `query`, `properties`, `limit` |

### Deal Management
| Tool | Description | Parameters |
|------|-------------|------------|
| `get_deals` | Retrieve deals with pagination | `limit`, `properties`, `after` |
| `create_deal` | Create new deal | `dealname` (required), other properties |
| `update_deal` | Update existing deal | `id`, `properties` |
| `search_deals` | Search deals by query | `query`, `properties`, `limit` |

### Relationship & Activity Tools
| Tool | Description | Parameters |
|------|-------------|------------|
| `get_associations` | Get object relationships | `objectId`, `objectType`, `toObjectType` |
| `get_engagement_history` | Get activity timeline | `objectId`, `objectType` |

## 📊 Resources

**8+ Live Resources Available:**
- `hubspot://contacts` - Live contacts database
- `hubspot://companies` - Live companies database  
- `hubspot://deals` - Live deals pipeline
- `hubspot://properties/contacts` - Contact property schema
- `hubspot://properties/companies` - Company property schema
- `hubspot://properties/deals` - Deal property schema
- `hubspot://pipelines/deals` - Deal pipeline configuration
- `hubspot://owners` - Sales rep/owner information

## 💡 Prompts

**5+ Ready-to-Use Prompts:**
- `analyze_pipeline` - Deal pipeline analysis and optimization
- `contact_research` - Deep contact and company research
- `lead_scoring` - Lead qualification and scoring
- `email_templates` - HubSpot email template generation  
- `meeting_prep` - Pre-meeting research and preparation

## 📈 Monitoring & Health

### Health Endpoints
| Endpoint | Purpose | Response |
|----------|---------|----------|
| `GET /health` | Basic health check | Health status and uptime |
| `GET /ready` | Readiness probe | Application readiness |
| `GET /metrics` | Prometheus metrics | Performance metrics |
| `GET /status` | Detailed status | Comprehensive server status |

### Example Usage
```bash
# Initialize session
curl -X POST http://localhost:3000/mcp/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"client"}}}'

# List available tools
curl -X POST http://localhost:3000/mcp/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{"sessionId":"session-id"}}'

# Get contacts
curl -X POST http://localhost:3000/mcp/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0","id":3,"method":"tools/call",
    "params":{
      "name":"get_contacts",
      "arguments":{"limit":5},
      "sessionId":"session-id"
    }
  }'
```

## 🔒 Security Features

- **Non-root execution** - Container runs as unprivileged user
- **Security hardening** - Read-only filesystem, dropped capabilities  
- **OWASP headers** - Complete security header implementation
- **Session management** - UUID-based sessions with timeouts
- **Rate limiting** - Configurable per-session rate limits
- **Input validation** - Comprehensive parameter validation

## 🛠️ Development

### Local Development
```bash
git clone https://github.com/SanketSKasar/HubSpot-MCP-Server.git
cd HubSpot-MCP-Server

# Install dependencies
npm install

# Set up environment
cp env.example .env
# Edit .env with your HubSpot token

# Run with different transports
npm start -- --transport http
npm start -- --transport streamable-http  
npm start -- --transport stdio

# Run tests
npm test

# Build Docker image
docker build -t hubspot-mcp-server .
```

### Command Line Options
```bash
node src/server.js --help

Options:
  --transport, -t    Transport protocol (http|streamable-http|stdio)
  --port, -p         Port to listen on (default: 3000)
  --host, -h         Host to bind to (default: 0.0.0.0)
  --log-level        Logging level (debug|info|warn|error)
  --max-connections  Maximum concurrent connections
  --session-timeout  Session timeout in seconds
```

## 📊 Performance

### Resource Requirements
| Environment | CPU | Memory | Concurrent Sessions |
|-------------|-----|--------|-------------------|
| **Minimum** | 0.25 cores | 256MB | 10 |
| **Recommended** | 0.5 cores | 512MB | 50 |
| **High Load** | 1+ cores | 1GB+ | 100+ |

### Monitoring
```bash
# Container metrics
docker stats hubspot-mcp-server

# Application metrics  
curl http://localhost:3000/metrics

# Performance testing
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:3000/health
```

## 🚀 Building Multi-Architecture Images

```bash
# Setup buildx for multi-arch
docker buildx create --name multiarch --use

# Build for multiple architectures with default port
docker buildx build \
  --build-arg EXPOSE_PORT=3000 \
  --platform linux/amd64,linux/arm64 \
  --tag ghcr.io/sanketskasar/hubspot-mcp-server:latest \
  --tag sanketskasar/hubspot-mcp-server:latest \
  --push .

# Build with custom port configuration
docker buildx build \
  --build-arg EXPOSE_PORT=8080 \
  --platform linux/amd64,linux/arm64 \
  --tag your-registry/hubspot-mcp-server:custom-port \
  --push .
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `npm test`
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Resources

- **[Model Context Protocol](https://modelcontextprotocol.io/)** - Official MCP specification
- **[HubSpot API Documentation](https://developers.hubspot.com/docs/api/overview)** - HubSpot CRM API
- **[MCP Protocol Specification](https://spec.modelcontextprotocol.io/)** - Technical MCP details

---

<div align="center">

## 📋 Latest Updates - Version 1.0.0

### **🎉 Production Release Features**
- ✅ **Complete Multi-Transport Support**: HTTP, Streamable HTTP (SSE), and STDIO protocols
- ✅ **Flexible Port Configuration**: Build-time and runtime port customization
- ✅ **Enhanced Session Management**: UUID-based sessions with comprehensive rate limiting
- ✅ **Multi-Architecture Images**: Native support for AMD64 and ARM64 platforms
- ✅ **Production Hardening**: OWASP security compliance and comprehensive monitoring
- ✅ **Streamlined Codebase**: Removed development components for production focus

### **🌍 Registry Availability**
- **GitHub Container Registry**: `ghcr.io/sanketskasar/hubspot-mcp-server:latest`
- **Docker Hub**: `sanketskasar/hubspot-mcp-server:latest`
- **Multi-Platform**: Both registries support AMD64 and ARM64 architectures

### **🔧 Key Capabilities**
- **21 MCP Protocol Endpoints**: Complete compliance with MCP Protocol Version 2024-11-05
- **15+ HubSpot Tools**: Full CRUD operations for contacts, companies, and deals
- **8+ Live Resources**: Real-time access to HubSpot CRM data and schemas
- **5+ Ready-to-Use Prompts**: Business intelligence and automation templates
- **Advanced Monitoring**: Health, readiness, metrics, and status endpoints
- **Enterprise Security**: Non-root execution, security headers, rate limiting

---

<div align="center">

**🎯 Built with ❤️ for the MCP ecosystem**

[![GitHub stars](https://img.shields.io/github/stars/SanketSKasar/HubSpot-MCP-Server?style=social)](https://github.com/SanketSKasar/HubSpot-MCP-Server/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/SanketSKasar/HubSpot-MCP-Server)](https://github.com/SanketSKasar/HubSpot-MCP-Server/issues)

</div>