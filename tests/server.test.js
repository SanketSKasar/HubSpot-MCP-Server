/**
 * MCP Server Test Suite
 * 
 * Tests for HubSpot MCP Server HTTP implementation
 * Validates MCP protocol compliance and core functionality
 */

'use strict';

const request = require('supertest');
const { createServer, CONFIG } = require('../src/server');

describe('HubSpot MCP Server - Protocol Implementation', () => {
  let app;

  beforeAll(async () => {
    // Set test environment
    process.env.NODE_ENV = 'test';
    process.env.HUBSPOT_PRIVATE_APP_ACCESS_TOKEN = 'pat-test-token-for-testing';
    process.env.PORT = '0';
    
    // Create server for testing
    app = createServer();
  });

  // Health and readiness endpoints
  describe('Health Endpoints', () => {
    test('GET /health should return server health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('version', CONFIG.appVersion);
      expect(response.body).toHaveProperty('service', CONFIG.appName);
    });

    test('GET /ready should return readiness status', async () => {
      const response = await request(app)
        .get('/ready')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'ready');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('checks');
      expect(response.body.checks).toHaveProperty('hubspot_token', true);
      expect(response.body.checks).toHaveProperty('server', 'running');
    });
  });

  // MCP Protocol endpoints
  describe('MCP Protocol Compliance', () => {
    test('POST /mcp/initialize should return server capabilities', async () => {
      const jsonRpcRequest = {
        jsonrpc: '2.0',
        id: 1,
        method: 'initialize',
        params: {}
      };

      const response = await request(app)
        .post('/mcp/initialize')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 1);
      expect(response.body).toHaveProperty('result');
      expect(response.body.result).toHaveProperty('protocolVersion');
      expect(response.body.result).toHaveProperty('capabilities');
      expect(response.body.result).toHaveProperty('serverInfo');
      expect(response.body.result.capabilities).toHaveProperty('tools');
      expect(response.body.result.capabilities).toHaveProperty('resources');
      expect(response.body.result.capabilities).toHaveProperty('prompts');
    });

    test('POST /mcp/tools/list should return available tools', async () => {
      const jsonRpcRequest = {
        jsonrpc: '2.0',
        id: 2,
        method: 'tools/list',
        params: {}
      };

      const response = await request(app)
        .post('/mcp/tools/list')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 2);
      expect(response.body).toHaveProperty('result');
      expect(response.body.result).toHaveProperty('tools');
      expect(Array.isArray(response.body.result.tools)).toBe(true);
      expect(response.body.result.tools.length).toBeGreaterThan(0);
      
      // Verify tool structure
      const tool = response.body.result.tools[0];
      expect(tool).toHaveProperty('name');
      expect(tool).toHaveProperty('description');
      expect(tool).toHaveProperty('inputSchema');
    });

    test('POST /mcp/resources/list should return available resources', async () => {
      const jsonRpcRequest = {
        jsonrpc: '2.0',
        id: 3,
        method: 'resources/list',
        params: {}
      };

      const response = await request(app)
        .post('/mcp/resources/list')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 3);
      expect(response.body).toHaveProperty('result');
      expect(response.body.result).toHaveProperty('resources');
      expect(Array.isArray(response.body.result.resources)).toBe(true);
      
      // Verify resource structure
      const resource = response.body.result.resources[0];
      expect(resource).toHaveProperty('uri');
      expect(resource).toHaveProperty('name');
      expect(resource).toHaveProperty('description');
      expect(resource).toHaveProperty('mimeType');
    });

    test('POST /mcp/prompts/list should return available prompts', async () => {
      const jsonRpcRequest = {
        jsonrpc: '2.0',
        id: 4,
        method: 'prompts/list',
        params: {}
      };

      const response = await request(app)
        .post('/mcp/prompts/list')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 4);
      expect(response.body).toHaveProperty('result');
      expect(response.body.result).toHaveProperty('prompts');
      expect(Array.isArray(response.body.result.prompts)).toBe(true);
    });

    test('POST /mcp/tools/call should handle tool execution errors gracefully', async () => {
      const jsonRpcRequest = {
        jsonrpc: '2.0',
        id: 5,
        method: 'tools/call',
        params: {
          name: 'get_contacts',
          arguments: { limit: 5 }
        }
      };

      const response = await request(app)
        .post('/mcp/tools/call')
        .send(jsonRpcRequest)
        .expect(200);

      // Should return JSON-RPC error due to test token
      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 5);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toHaveProperty('code', -32603);
      expect(response.body.error).toHaveProperty('message');
    });

    test('Should handle unknown MCP methods', async () => {
      const jsonRpcRequest = {
        jsonrpc: '2.0',
        id: 6,
        method: 'unknown/method',
        params: {}
      };

      const response = await request(app)
        .post('/mcp/unknown')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 6);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toHaveProperty('code', -32603);
    });
  });

  // Security and error handling
  describe('Security & Error Handling', () => {
    test('Should include OWASP security headers', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.headers).toHaveProperty('x-content-type-options', 'nosniff');
      expect(response.headers).toHaveProperty('x-frame-options', 'DENY');
      expect(response.headers).toHaveProperty('x-xss-protection', '1; mode=block');
      expect(response.headers).toHaveProperty('content-security-policy', "default-src 'none'");
      expect(response.headers).toHaveProperty('referrer-policy', 'no-referrer');
    });

    test('Should handle CORS preflight requests', async () => {
      const response = await request(app)
        .options('/mcp/initialize')
        .expect(200);
    });

    test('Should handle invalid JSON-RPC requests', async () => {
      const response = await request(app)
        .post('/mcp/initialize')
        .send('invalid json')
        .expect(500);

      expect(response.body).toHaveProperty('error');
      expect(response.body).toHaveProperty('message');
    });

    test('Should return 404 for unknown endpoints', async () => {
      const response = await request(app)
        .get('/unknown-endpoint')
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Not Found');
      expect(response.body).toHaveProperty('message', 'Endpoint not found');
    });
  });

  // Configuration validation
  describe('Configuration', () => {
    test('Should use environment variables for configuration', () => {
      expect(CONFIG.hubspotToken).toBe('pat-test-token-for-testing');
      expect(CONFIG.nodeEnv).toBe('test');
      expect(CONFIG.appName).toBe('hubspot-mcp-server');
    });
  });
});