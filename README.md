# HubSpot MCP Server

[![Docker Hub](https://img.shields.io/docker/pulls/yourusername/hubspot-mcp-server)](https://hub.docker.com/r/yourusername/hubspot-mcp-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A complete Model Context Protocol (MCP) server for HubSpot CRM integration, implementing all 21 MCP protocol endpoints over HTTP using JSON-RPC 2.0.

## Features

- **Complete MCP Protocol**: All 21 endpoints (initialize, tools, resources, prompts, notifications, logging)
- **HubSpot Integration**: 8 CRM tools for contacts, companies, and deals
- **Enterprise Security**: OWASP compliance, container hardening, non-root execution
- **Production Ready**: Health checks, structured logging, graceful shutdown
- **Docker Native**: Multi-stage builds, minimal Alpine base, automatic restarts

## Quick Start

1. **Get HubSpot Token**: Create a Private App in HubSpot Settings → Integrations → Private Apps
2. **Run Container**:
   ```bash
   docker run -d \
     --name hubspot-mcp-server \
     -p 3000:3000 \
     -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here \
     --restart unless-stopped \
     yourusername/hubspot-mcp-server:latest
   ```
3. **Test**: `curl http://localhost:3000/health`

## Configuration

Copy `env.example` to `.env` and configure:

```bash
# Required
HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=your_token_here

# Optional (with defaults)
PORT=3000
NODE_ENV=production
LOG_LEVEL=info
```

### Required HubSpot Scopes

- `crm.objects.contacts.read`
- `crm.objects.contacts.write` 
- `crm.objects.companies.read`
- `crm.objects.deals.read`

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

## Available Tools

- `get_contacts` - Retrieve contacts with pagination
- `search_contacts` - Search contacts by query
- `get_contact_by_id` - Get specific contact details
- `create_contact` - Create new contacts
- `get_companies` - Retrieve companies
- `get_company_by_id` - Get specific company
- `get_deals` - Retrieve deals from pipeline
- `get_deal_by_id` - Get specific deal details

## Health Endpoints

- `GET /health` - Container health check
- `GET /ready` - Application readiness probe

## Build from Source

```bash
git clone https://github.com/yourusername/hubspot-mcp-server
cd hubspot-mcp-server
docker build -t hubspot-mcp-server .
```

## Docker Compose

```yaml
version: '3.8'
services:
  hubspot-mcp-server:
    image: yourusername/hubspot-mcp-server:latest
    ports:
      - "3000:3000"
    environment:
      - HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=${HUBSPOT_PRIVATE_APP_ACCESS_TOKEN}
      - NODE_ENV=production
    restart: unless-stopped
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Documentation

- [Complete MCP Guide](docs/COMPLETE_MCP_GUIDE.md) - Detailed protocol documentation
- [MCP Protocol Reference](docs/MCP_PROTOCOL_GUIDE.md) - Technical specification
- [Development Scripts](dev/) - Testing and deployment utilities