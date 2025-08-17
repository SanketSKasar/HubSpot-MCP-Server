# HubSpot MCP Server

[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-Available-brightgreen?logo=github)](https://github.com/SanketSKasar/HubSpot-MCP-Server/pkgs/container/hubspot-mcp-server)
[![Docker Hub](https://img.shields.io/badge/docker.hub-Coming%20Soon-orange?logo=docker)](https://hub.docker.com/r/sanketskasar/hubspot-mcp-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-20.12.0-green?logo=node.js)](https://nodejs.org/)
[![Docker](https://img.shields.io/badge/Docker-Multi--Stage-blue?logo=docker)](https://docker.com/)
[![MCP Protocol](https://img.shields.io/badge/MCP-21%20Endpoints-purple)](https://modelcontextprotocol.io/)

🚀 A complete **Model Context Protocol (MCP)** server for HubSpot CRM integration, implementing all 21 MCP protocol endpoints over HTTP using JSON-RPC 2.0.

## 📦 Available Images

| Registry | Image | Status | Command |
|----------|-------|--------|---------|
| **GitHub Container Registry** | `ghcr.io/sanketskasar/hubspot-mcp-server:latest` | ✅ **Available** | `docker pull ghcr.io/sanketskasar/hubspot-mcp-server:latest` |
| **Docker Hub** | `sanketskasar/hubspot-mcp-server:latest` | 🚧 Coming Soon | `docker pull sanketskasar/hubspot-mcp-server:latest` |

> **Note:** Currently using GitHub Container Registry. Docker Hub mirror coming soon!

## Features

- **Complete MCP Protocol**: All 21 endpoints (initialize, tools, resources, prompts, notifications, logging)
- **HubSpot Integration**: 8 CRM tools for contacts, companies, and deals
- **Enterprise Security**: OWASP compliance, container hardening, non-root execution
- **Production Ready**: Health checks, structured logging, graceful shutdown
- **Docker Native**: Multi-stage builds, minimal Alpine base, automatic restarts

## 🚀 Quick Start

### Prerequisites
- Docker installed on your system
- HubSpot Private App Access Token ([Get one here](#hubspot-setup))

### 1. Get HubSpot Token
Create a Private App in HubSpot Settings → Integrations → Private Apps with these scopes:
- `crm.objects.contacts.read`
- `crm.objects.contacts.write`
- `crm.objects.companies.read`
- `crm.objects.deals.read`

### 2. Run Container

**🟢 Currently Available (GitHub Container Registry):**
```bash
docker run -d \
  --name hubspot-mcp-server \
  -p 3000:3000 \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here \
  --restart unless-stopped \
  ghcr.io/sanketskasar/hubspot-mcp-server:latest
```

**🟡 Coming Soon (Docker Hub):**
```bash
docker run -d \
  --name hubspot-mcp-server \
  -p 3000:3000 \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here \
  --restart unless-stopped \
  sanketskasar/hubspot-mcp-server:latest
```

### 3. Verify Installation
```bash
# Check container status
docker ps | grep hubspot-mcp-server

# Test health endpoint
curl http://localhost:3000/health

# Expected response:
# {"status":"healthy","timestamp":"...","uptime":...,"version":"1.0.0"}
```

## ⚙️ Configuration

### Environment Variables

Copy `env.example` to `.env` and configure:

```bash
# ========================================
# Required Configuration
# ========================================
HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here

# ========================================
# Optional Configuration (with defaults)
# ========================================

# Server Configuration
PORT=3000
HOST=0.0.0.0

# Environment
NODE_ENV=production
LOG_LEVEL=info

# HubSpot API
HUBSPOT_API_URL=https://api.hubapi.com

# Security
CORS_ORIGIN=localhost
MAX_REQUEST_SIZE=10485760

# Performance
GRACEFUL_SHUTDOWN_TIMEOUT=10000
```

## 🔑 HubSpot Setup

### Step 1: Create a Private App

1. **Go to HubSpot Settings:**
   - In your HubSpot account, click the settings gear in the main navigation
   - Navigate to **Integrations** → **Private Apps**

2. **Create New Private App:**
   - Click **"Create a private app"**
   - Give it a name (e.g., "MCP Server Integration")
   - Add a description

3. **Configure Scopes:**
   Select the following scopes in the **Scopes** tab:

#### Required Scopes
| Scope | Purpose |
|-------|----------|
| `crm.objects.contacts.read` | Read contact information |
| `crm.objects.contacts.write` | Create and update contacts |
| `crm.objects.companies.read` | Read company information |
| `crm.objects.deals.read` | Read deal information |

4. **Generate Token:**
   - Go to the **Auth** tab
   - Copy the **Access Token** (starts with `pat-...`)
   - **⚠️ Keep this token secure!**

### Step 2: Test Your Token

```bash
# Test the token works
curl -H "Authorization: Bearer YOUR_TOKEN" \
     "https://api.hubapi.com/crm/v3/objects/contacts?limit=1"
```

### Step 3: Use with Docker

```bash
# Replace YOUR_TOKEN with your actual token
docker run -d \
  --name hubspot-mcp-server \
  -p 3000:3000 \
  -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=YOUR_TOKEN \
  ghcr.io/sanketskasar/hubspot-mcp-server:latest
```

## API Usage

All MCP endpoints are available at `http://localhost:3000/` using JSON-RPC 2.0:

```bash
# Initialize MCP session
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'

# List available tools
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

# Call a tool
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":3,
    "method":"tools/call",
    "params":{
      "name":"get_contacts",
      "arguments":{"limit":10}
    }
  }'
```

## 🛠️ Available Tools

The server implements **8 HubSpot CRM tools** through the MCP protocol:

### 👥 Contact Tools
| Tool | Description | Parameters |
|------|-------------|------------|
| `get_contacts` | Retrieve contacts with pagination | `limit` (optional), `after` (optional) |
| `search_contacts` | Search contacts by query | `query` (required), `limit` (optional) |
| `get_contact_by_id` | Get specific contact details | `contact_id` (required) |
| `create_contact` | Create new contacts | `email` (required), `properties` (optional) |

### 🏢 Company Tools
| Tool | Description | Parameters |
|------|-------------|------------|
| `get_companies` | Retrieve companies with pagination | `limit` (optional), `after` (optional) |
| `get_company_by_id` | Get specific company details | `company_id` (required) |

### 💼 Deal Tools
| Tool | Description | Parameters |
|------|-------------|------------|
| `get_deals` | Retrieve deals from pipeline | `limit` (optional), `after` (optional) |
| `get_deal_by_id` | Get specific deal details | `deal_id` (required) |

### Example Tool Usage

```bash
# Get first 5 contacts
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"get_contacts",
      "arguments":{"limit":5}
    }
  }'

# Search for contacts
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":2,
    "method":"tools/call",
    "params":{
      "name":"search_contacts",
      "arguments":{"query":"john@example.com"}
    }
  }'

# Create a new contact
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":3,
    "method":"tools/call",
    "params":{
      "name":"create_contact",
      "arguments":{
        "email":"new@example.com",
        "properties":{
          "firstname":"John",
          "lastname":"Doe",
          "company":"Example Corp"
        }
      }
    }
  }'
```

## Health Endpoints

- `GET /health` - Container health check
- `GET /ready` - Application readiness probe

## Build from Source

```bash
git clone https://github.com/SanketSKasar/HubSpot-MCP-Server.git
cd HubSpot-MCP-Server
docker build -t hubspot-mcp-server .
```

## Docker Compose

```yaml
version: '3.8'
services:
  hubspot-mcp-server:
    # ✅ Currently Available - GitHub Container Registry
    image: ghcr.io/sanketskasar/hubspot-mcp-server:latest
    
    # 🚧 Coming Soon - Docker Hub
    # image: sanketskasar/hubspot-mcp-server:latest
    
    container_name: hubspot-mcp-server
    ports:
      - "3000:3000"
    environment:
      - HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=${HUBSPOT_PRIVATE_APP_ACCESS_TOKEN}
      - NODE_ENV=production
      - LOG_LEVEL=info
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

**Usage:**
```bash
# Create .env file
echo "HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here" > .env

# Start the service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```



## 🟡 Health Endpoints

The server provides health check endpoints for monitoring:

### Available Endpoints

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `GET /health` | Container health check | Health status with uptime |
| `GET /ready` | Application readiness probe | Readiness status |

### Health Check Examples

```bash
# Basic health check
curl http://localhost:3000/health

# Response:
{
  "status": "healthy",
  "timestamp": "2025-01-17T12:00:00.000Z",
  "uptime": 3600,
  "version": "1.0.0",
  "service": "hubspot-mcp-server",
  "initialized": true
}

# Readiness probe
curl http://localhost:3000/ready

# Response:
{
  "status": "ready",
  "timestamp": "2025-01-17T12:00:00.000Z"
}
```

### Docker Health Checks

The Docker image includes built-in health checks:

```bash
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# View health check logs
docker inspect hubspot-mcp-server | jq '.[0].State.Health'
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Container Won't Start
```bash
# Check container logs
docker logs hubspot-mcp-server

# Common causes:
# - Missing HUBSPOT_PRIVATE_APP_ACCESS_TOKEN
# - Invalid token
# - Port already in use
```

#### 2. Health Check Failing
```bash
# Test health endpoint manually
curl -f http://localhost:3000/health

# Check if container is running
docker ps | grep hubspot-mcp-server

# Restart container
docker restart hubspot-mcp-server
```

#### 3. HubSpot API Errors
```bash
# Check your token permissions
curl -H "Authorization: Bearer YOUR_TOKEN" \
     "https://api.hubapi.com/crm/v3/objects/contacts?limit=1"

# Common HTTP status codes:
# 401 - Invalid or expired token
# 403 - Insufficient permissions
# 429 - Rate limit exceeded
```

#### 4. Performance Issues
```bash
# Monitor container resources
docker stats hubspot-mcp-server

# Check container logs for errors
docker logs -f hubspot-mcp-server

# Adjust container resources if needed
docker run --memory=1g --cpus=1 ...
```

### Getting Help

- 🐛 **Issues:** [Report bugs](https://github.com/SanketSKasar/HubSpot-MCP-Server/issues)
- 💬 **Discussions:** [Ask questions](https://github.com/SanketSKasar/HubSpot-MCP-Server/discussions)
- 📚 **Documentation:** [Complete guides](docs/)

## 📊 Performance & Monitoring

### Resource Requirements

| Environment | CPU | Memory | Disk |
|-------------|-----|--------|----- |
| **Minimum** | 0.25 cores | 256MB | 1GB |
| **Recommended** | 0.5 cores | 512MB | 2GB |
| **High Load** | 1+ cores | 1GB+ | 5GB+ |

### Monitoring

```bash
# Container metrics
docker stats hubspot-mcp-server --no-stream

# Application logs
docker logs -f hubspot-mcp-server | jq .

# Health monitoring
while true; do
  curl -s http://localhost:3000/health | jq '.status'
  sleep 30
done
```

## 🛠️ Development

### Local Development

```bash
# Clone repository
git clone https://github.com/SanketSKasar/HubSpot-MCP-Server.git
cd HubSpot-MCP-Server

# Install dependencies
npm install

# Set up environment
cp env.example .env
# Edit .env with your HubSpot token

# Run locally
npm start

# Run tests
npm test

# Lint code
npm run lint
```

### Building Custom Images

```bash
# Build development image
./scripts/build.sh -e dev

# Build production image
./scripts/build.sh -e prod

# Build and push to registries
./scripts/build.sh -p

# Multi-architecture build
./scripts/build.sh -m

# Build with security scan
./scripts/build.sh -s
```

## 🔒 Security

### Security Features

- ✅ **Non-root execution** - Container runs as unprivileged user
- ✅ **Minimal base image** - Alpine Linux for reduced attack surface
- ✅ **Security hardening** - Read-only filesystem, dropped capabilities
- ✅ **Environment isolation** - Proper secret management
- ✅ **Health monitoring** - Built-in health checks

### Best Practices

1. **Secure Token Storage:**
   ```bash
   # Use Docker secrets in production
   echo "YOUR_TOKEN" | docker secret create hubspot_token -
   
   # Reference in compose file
   secrets:
     - hubspot_token
   ```

2. **Network Security:**
   ```bash
   # Run on custom network
   docker network create hubspot-net
   docker run --network hubspot-net ...
   ```

3. **Log Security:**
   ```bash
   # Avoid logging sensitive data
   export LOG_LEVEL=warn  # Reduces verbose logging
   ```

## 🔄 Updates & Releases

### Staying Updated

```bash
# Pull latest image
docker pull ghcr.io/sanketskasar/hubspot-mcp-server:latest

# Restart with new image
docker-compose pull && docker-compose up -d

# Check version
curl http://localhost:3000/health | jq '.version'
```

### Release Notes

- **v1.0.0** - Initial release with all 21 MCP endpoints
- More releases coming soon...

## 🔗 Related Projects

- **[Model Context Protocol](https://modelcontextprotocol.io/)** - Official MCP specification
- **[HubSpot API](https://developers.hubspot.com/docs/api/overview)** - HubSpot CRM API documentation
- **[MCP Specification](https://spec.modelcontextprotocol.io/)** - Technical MCP protocol details

## 🎆 Enhanced Contributing

We welcome contributions! Here's how to get started:

### Quick Start

1. **🔀 Fork** the repository
2. **🌱 Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **✨ Commit** your changes: `git commit -m 'Add amazing feature'`
4. **🚀 Push** to branch: `git push origin feature/amazing-feature`
5. **🔄 Create** a Pull Request

### Development Setup

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/HubSpot-MCP-Server.git
cd HubSpot-MCP-Server

# Install dependencies
npm install

# Set up environment
cp env.example .env
# Add your HubSpot token to .env

# Run tests
npm test

# Start development server
npm start
```

### Contribution Guidelines

- ✅ Follow existing code style
- ✅ Add tests for new features
- ✅ Update documentation
- ✅ Ensure Docker builds work
- ✅ Keep commits atomic and well-described

### Areas for Contribution

- 🐛 **Bug fixes** - Report and fix issues
- ✨ **New features** - Add MCP tools or endpoints
- 📚 **Documentation** - Improve guides and examples
- 🔒 **Security** - Enhance security measures
- 🎨 **UI/UX** - Better developer experience
- 🎧 **Performance** - Optimize response times

## 📜 License

```text
MIT License

Copyright (c) 2025 SanketSKasar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**View full license:** [LICENSE](LICENSE)

## 📚 Documentation

### 📋 Core Documentation

| Document | Description | Link |
|----------|-------------|----- |
| **Complete MCP Guide** | Detailed protocol documentation | [docs/COMPLETE_MCP_GUIDE.md](docs/COMPLETE_MCP_GUIDE.md) |
| **MCP Protocol Reference** | Technical specification | [docs/MCP_PROTOCOL_GUIDE.md](docs/MCP_PROTOCOL_GUIDE.md) |
| **Development Scripts** | Testing and deployment utilities | [dev/](dev/) |
| **Security Policy** | Security guidelines and reporting | [SECURITY.md](SECURITY.md) |
| **Contributing Guide** | Contribution guidelines | [CONTRIBUTING.md](CONTRIBUTING.md) |

### 🔗 External Resources

- **[HubSpot API Documentation](https://developers.hubspot.com/docs/api/overview)** - Official HubSpot API docs
- **[Model Context Protocol](https://modelcontextprotocol.io/)** - Official MCP website
- **[MCP Specification](https://spec.modelcontextprotocol.io/)** - Technical protocol spec
- **[Docker Documentation](https://docs.docker.com/)** - Docker usage guides

---

<div align="center">

**🎆 Built with ❤️ by [SanketSKasar](https://github.com/SanketSKasar)**

**⭐ Star this repo if you find it helpful!**

[![GitHub stars](https://img.shields.io/github/stars/SanketSKasar/HubSpot-MCP-Server?style=social)](https://github.com/SanketSKasar/HubSpot-MCP-Server/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/SanketSKasar/HubSpot-MCP-Server?style=social)](https://github.com/SanketSKasar/HubSpot-MCP-Server/network/members)
[![GitHub issues](https://img.shields.io/github/issues/SanketSKasar/HubSpot-MCP-Server)](https://github.com/SanketSKasar/HubSpot-MCP-Server/issues)

</div>