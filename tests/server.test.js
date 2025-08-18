/**
 * HubSpot MCP Server Test Suite
 * 
 * Comprehensive tests for the multi-transport MCP server implementation
 * Validates protocol compliance, session management, and HubSpot integration
 */

'use strict';

const request = require('supertest');
const { createTransport, MCPServer, HubSpotClient, SessionManager, CONFIG } = require('../src/server');
const { testUtils, mockNetworkRequests } = require('./setup');

describe('HubSpot MCP Server - Complete Implementation', () => {
  let httpTransport;
  let sessionManager;
  let mcpServer;
  let hubspotClient;

  beforeAll(async () => {
    // Mock network requests to prevent external API calls
    mockNetworkRequests();
    
    // Initialize components
    hubspotClient = new HubSpotClient(CONFIG.hubspotToken, CONFIG.hubspotApiUrl);
    sessionManager = new SessionManager();
    mcpServer = new MCPServer(hubspotClient, sessionManager);
    httpTransport = createTransport('http', mcpServer, sessionManager);
  });

  // Health and monitoring endpoints
  describe('Health & Monitoring Endpoints', () => {
    test('GET /health should return comprehensive health status', async () => {
      const response = await request(httpTransport.server)
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('version', CONFIG.appVersion);
      expect(response.body).toHaveProperty('service', CONFIG.appName);
      expect(response.body).toHaveProperty('transport', CONFIG.transport);
      expect(response.body).toHaveProperty('sessions');
    });

    test('GET /ready should return readiness status with detailed checks', async () => {
      const response = await request(httpTransport.server)
        .get('/ready')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'ready');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('checks');
      expect(response.body.checks).toHaveProperty('hubspot_token', true);
      expect(response.body.checks).toHaveProperty('server', 'running');
      expect(response.body.checks).toHaveProperty('uptime');
      expect(response.body.checks).toHaveProperty('sessions');
    });

    test('GET /metrics should return performance metrics', async () => {
      const response = await request(httpTransport.server)
        .get('/metrics')
        .expect(200);

      expect(response.body).toHaveProperty('requests_total');
      expect(response.body).toHaveProperty('active_sessions');
      expect(response.body).toHaveProperty('hubspot_api_calls');
      expect(response.body).toHaveProperty('errors_total');
      expect(response.body).toHaveProperty('tool_usage');
      expect(response.body).toHaveProperty('timestamp');
    });

    test('GET /status should return detailed server status', async () => {
      const response = await request(httpTransport.server)
        .get('/status')
        .expect(200);

      expect(response.body).toHaveProperty('service', CONFIG.appName);
      expect(response.body).toHaveProperty('version', CONFIG.appVersion);
      expect(response.body).toHaveProperty('transport', CONFIG.transport);
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('sessions');
      expect(response.body).toHaveProperty('config');
      expect(response.body.config).toHaveProperty('hubspot_connected', true);
    });
  });

  // MCP Protocol compliance tests
  describe('MCP Protocol Compliance', () => {
    let sessionId;

    test('initialize method should create session and return capabilities', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('initialize', {
        clientInfo: { name: 'test-client', version: '1.0.0' }
      });

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 1);
      expect(response.body).toHaveProperty('result');
      
      const result = response.body.result;
      expect(result).toHaveProperty('protocolVersion', '2024-11-05');
      expect(result).toHaveProperty('capabilities');
      expect(result).toHaveProperty('serverInfo');
      expect(result).toHaveProperty('sessionId');
      
      // Validate capabilities structure
      expect(result.capabilities).toHaveProperty('tools');
      expect(result.capabilities).toHaveProperty('resources');
      expect(result.capabilities).toHaveProperty('prompts');
      expect(result.capabilities.tools).toHaveProperty('listChanged', true);
      expect(result.capabilities.resources).toHaveProperty('subscribe', true);
      
      sessionId = result.sessionId;
      expect(sessionId).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
    });

    test('ping method should respond correctly', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('ping', { sessionId }, 2);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 2);
      expect(response.body).toHaveProperty('result', {});
    });

    test('tools/list should return all 15+ HubSpot tools', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('tools/list', { sessionId }, 3);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 3);
      expect(response.body).toHaveProperty('result');
      expect(response.body.result).toHaveProperty('tools');
      
      const tools = response.body.result.tools;
      expect(Array.isArray(tools)).toBe(true);
      expect(tools.length).toBeGreaterThanOrEqual(15);
      
      // Verify essential tools are present
      const toolNames = tools.map(tool => tool.name);
      expect(toolNames).toContain('get_contacts');
      expect(toolNames).toContain('get_companies');
      expect(toolNames).toContain('get_deals');
      expect(toolNames).toContain('create_contact');
      expect(toolNames).toContain('search_contacts');
      expect(toolNames).toContain('get_associations');
      
      // Verify tool structure
      tools.forEach(tool => {
        expect(tool).toHaveProperty('name');
        expect(tool).toHaveProperty('description');
        expect(tool).toHaveProperty('inputSchema');
        expect(tool.inputSchema).toHaveProperty('type', 'object');
      });
    });

    test('resources/list should return all 8+ HubSpot resources', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('resources/list', { sessionId }, 4);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('result');
      expect(response.body.result).toHaveProperty('resources');
      
      const resources = response.body.result.resources;
      expect(Array.isArray(resources)).toBe(true);
      expect(resources.length).toBeGreaterThanOrEqual(8);
      
      // Verify essential resources are present
      const resourceUris = resources.map(resource => resource.uri);
      expect(resourceUris).toContain('hubspot://contacts');
      expect(resourceUris).toContain('hubspot://companies');
      expect(resourceUris).toContain('hubspot://deals');
      expect(resourceUris).toContain('hubspot://properties/contacts');
      expect(resourceUris).toContain('hubspot://owners');
      
      // Verify resource structure
      resources.forEach(resource => {
        expect(resource).toHaveProperty('uri');
        expect(resource).toHaveProperty('name');
        expect(resource).toHaveProperty('description');
        expect(resource).toHaveProperty('mimeType', 'application/json');
      });
    });

    test('prompts/list should return all 5+ HubSpot prompts', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('prompts/list', { sessionId }, 5);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('result');
      expect(response.body.result).toHaveProperty('prompts');
      
      const prompts = response.body.result.prompts;
      expect(Array.isArray(prompts)).toBe(true);
      expect(prompts.length).toBeGreaterThanOrEqual(5);
      
      // Verify essential prompts are present
      const promptNames = prompts.map(prompt => prompt.name);
      expect(promptNames).toContain('analyze_pipeline');
      expect(promptNames).toContain('contact_research');
      expect(promptNames).toContain('lead_scoring');
      
      // Verify prompt structure
      prompts.forEach(prompt => {
        expect(prompt).toHaveProperty('name');
        expect(prompt).toHaveProperty('description');
        expect(prompt).toHaveProperty('arguments');
        expect(Array.isArray(prompt.arguments)).toBe(true);
      });
    });

    test('tools/call should handle tool execution with session management', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('tools/call', {
        name: 'get_contacts',
        arguments: { limit: 5 },
        sessionId
      }, 6);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 6);
      
      // Should either return result or error (due to mocked API)
      if (response.body.result) {
        expect(response.body.result).toHaveProperty('content');
        expect(Array.isArray(response.body.result.content)).toBe(true);
      } else {
        expect(response.body).toHaveProperty('error');
        expect(response.body.error).toHaveProperty('code', -32603);
      }
    });

    test('resources/subscribe should create subscription', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('resources/subscribe', {
        uri: 'hubspot://contacts',
        sessionId
      }, 7);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('result');
      expect(response.body.result).toHaveProperty('subscriptionId');
      expect(response.body.result.subscriptionId).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
    });

    test('logging/setLevel should update log level', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('logging/setLevel', {
        level: 'debug',
        sessionId
      }, 8);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('result', {});
    });

    test('should handle unknown methods gracefully', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('unknown/method', { sessionId }, 9);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('jsonrpc', '2.0');
      expect(response.body).toHaveProperty('id', 9);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toHaveProperty('code', -32603);
      expect(response.body.error.message).toContain('Method not found');
    });
  });

  // Session management tests
  describe('Session Management', () => {
    test('should require session for protected methods', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('tools/list', {}, 10);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error.message).toContain('Session not initialized');
    });

    test('should handle invalid session IDs', async () => {
      const jsonRpcRequest = testUtils.createMCPRequest('tools/list', {
        sessionId: 'invalid-session-id'
      }, 11);

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(jsonRpcRequest)
        .expect(200);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error.message).toContain('Session not initialized');
    });
  });

  // Security and error handling
  describe('Security & Error Handling', () => {
    test('should include comprehensive security headers', async () => {
      const response = await request(httpTransport.server)
        .get('/health')
        .expect(200);

      expect(response.headers).toHaveProperty('x-content-type-options', 'nosniff');
      expect(response.headers).toHaveProperty('x-frame-options', 'DENY');
      expect(response.headers).toHaveProperty('x-xss-protection', '1; mode=block');
      expect(response.headers).toHaveProperty('content-security-policy', "default-src 'none'");
      expect(response.headers).toHaveProperty('strict-transport-security', 'max-age=31536000');
      expect(response.headers).toHaveProperty('referrer-policy', 'no-referrer');
    });

    test('should handle CORS preflight requests', async () => {
      await request(httpTransport.server)
        .options('/mcp/')
        .expect(200);
    });

    test('should handle malformed JSON requests', async () => {
      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send('invalid json')
        .expect(500);

      expect(response.body).toHaveProperty('error');
      expect(response.body).toHaveProperty('message');
    });

    test('should return 404 for unknown endpoints', async () => {
      const response = await request(httpTransport.server)
        .get('/unknown-endpoint')
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Not Found');
      expect(response.body).toHaveProperty('message', 'Endpoint not found');
    });

    test('should handle request size limits', async () => {
      const largePayload = testUtils.createMCPRequest('initialize', {
        clientInfo: { 
          name: 'test-client',
          largeData: 'x'.repeat(CONFIG.maxRequestSize + 1000)
        }
      });

      const response = await request(httpTransport.server)
        .post('/mcp/')
        .send(largePayload)
        .expect(500);

      expect(response.body).toHaveProperty('error');
    });
  });

  // Transport-specific tests
  describe('Multi-Transport Architecture', () => {
    test('should support HTTP transport configuration', () => {
      expect(CONFIG.transport).toBe('http');
      expect(httpTransport).toBeDefined();
      expect(httpTransport.server).toBeDefined();
    });

    test('should create appropriate transport instances', () => {
      const transportTypes = ['http', 'streamable-http', 'stdio'];
      
      transportTypes.forEach(type => {
        const transport = createTransport(type, mcpServer, sessionManager);
        expect(transport).toBeDefined();
        expect(transport.mcpServer).toBe(mcpServer);
        expect(transport.sessionManager).toBe(sessionManager);
      });
    });
  });

  // Configuration validation
  describe('Configuration Management', () => {
    test('should load configuration from environment variables', () => {
      expect(CONFIG.hubspotToken).toBe('pat-test-token-for-jest-testing');
      expect(CONFIG.transport).toBe('http');
      expect(CONFIG.appName).toBe('hubspot-mcp-server');
      expect(CONFIG.mcpProtocolVersion).toBe('2024-11-05');
    });

    test('should have reasonable default values', () => {
      expect(CONFIG.port).toBe(0); // Test port
      expect(CONFIG.host).toBe('0.0.0.0');
      expect(CONFIG.maxConnections).toBe(10); // Test value
      expect(CONFIG.sessionTimeout).toBe(300); // Test value
    });
  });

  // Component integration tests
  describe('Component Integration', () => {
    test('SessionManager should manage sessions correctly', () => {
      const session = sessionManager.createSession({ name: 'test-client' });
      expect(session).toHaveProperty('id');
      expect(session).toHaveProperty('clientInfo');
      expect(session).toHaveProperty('createdAt');
      expect(session).toHaveProperty('initialized', false);

      const retrieved = sessionManager.getSession(session.id);
      expect(retrieved).toBe(session);
      expect(retrieved.lastActivity).toBeGreaterThan(session.lastActivity);

      const removed = sessionManager.removeSession(session.id);
      expect(removed).toBe(true);
      expect(sessionManager.getSession(session.id)).toBeUndefined();
    });

    test('HubSpotClient should be properly configured', () => {
      expect(hubspotClient).toBeInstanceOf(HubSpotClient);
      expect(hubspotClient.token).toBe(CONFIG.hubspotToken);
      expect(hubspotClient.apiUrl).toBe(CONFIG.hubspotApiUrl);
    });

    test('MCPServer should have correct capabilities', () => {
      expect(mcpServer).toBeInstanceOf(MCPServer);
      expect(mcpServer.serverInfo).toHaveProperty('name', CONFIG.appName);
      expect(mcpServer.serverInfo).toHaveProperty('version', CONFIG.appVersion);
      expect(mcpServer.serverInfo).toHaveProperty('protocolVersion', '2024-11-05');
      expect(mcpServer.capabilities).toHaveProperty('tools');
      expect(mcpServer.capabilities).toHaveProperty('resources');
      expect(mcpServer.capabilities).toHaveProperty('prompts');
    });
  });
});