/**
 * Jest Test Setup
 * 
 * Global test configuration and setup for the HubSpot MCP Server test suite.
 * This file is run before all tests to configure the testing environment.
 */

'use strict';

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.LOG_LEVEL = 'error'; // Reduce log noise during tests
process.env.HUBSPOT_PRIVATE_APP_ACCESS_TOKEN = 'pat-test-token-for-jest-testing';
process.env.TRANSPORT = 'http';
process.env.PORT = '0'; // Use random available port for tests
process.env.MAX_CONNECTIONS = '10';
process.env.SESSION_TIMEOUT = '300'; // 5 minutes for tests
process.env.RATE_LIMIT_TOOLS = '1000'; // Higher limits for tests
process.env.RATE_LIMIT_RESOURCES = '1000';

// Increase timeout for slower operations
jest.setTimeout(30000);

// Global test utilities
global.testUtils = {
  /**
   * Wait for a specified amount of time
   * @param {number} ms - Milliseconds to wait
   * @returns {Promise<void>}
   */
  wait: (ms) => new Promise(resolve => setTimeout(resolve, ms)),

  /**
   * Generate a random string for testing
   * @param {number} length - Length of the string
   * @returns {string}
   */
  randomString: (length = 10) => {
    return Math.random().toString(36).substring(2, 2 + length);
  },

  /**
   * Generate test MCP JSON-RPC request
   * @param {string} method - MCP method name
   * @param {Object} params - Method parameters
   * @param {number} id - Request ID
   * @returns {Object}
   */
  createMCPRequest: (method, params = {}, id = 1) => {
    return {
      jsonrpc: '2.0',
      id,
      method,
      params
    };
  },

  /**
   * Generate test session data
   * @param {Object} overrides - Override default values
   * @returns {Object}
   */
  createTestSession: (overrides = {}) => {
    return {
      id: 'test-session-' + Math.random().toString(36).substring(7),
      clientInfo: { name: 'test-client', version: '1.0.0' },
      createdAt: Date.now(),
      lastActivity: Date.now(),
      initialized: true,
      ...overrides
    };
  },

  /**
   * Generate test tool call parameters
   * @param {string} toolName - Name of the tool
   * @param {Object} args - Tool arguments
   * @returns {Object}
   */
  createToolCall: (toolName, args = {}) => {
    return {
      name: toolName,
      arguments: args
    };
  },

  /**
   * Mock HubSpot API response
   * @param {Object} data - Response data
   * @returns {Object}
   */
  createMockHubSpotResponse: (data = {}) => {
    return {
      results: Array.isArray(data) ? data : [data],
      total: Array.isArray(data) ? data.length : 1,
      ...data
    };
  }
};

// Mock console methods in test environment to reduce noise
const originalConsole = global.console;

// Keep important console methods for debugging failures
global.console = {
  ...originalConsole,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  // Keep warn and error for debugging
  warn: originalConsole.warn,
  error: originalConsole.error
};

// Restore console after all tests
afterAll(() => {
  global.console = originalConsole;
});

// Clean up environment after each test
afterEach(() => {
  // Clear all timers
  jest.clearAllTimers();
  
  // Clear all mocks
  jest.clearAllMocks();
});

// Handle uncaught exceptions and unhandled rejections in tests
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception in test:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection in test:', reason);
  process.exit(1);
});

// Performance monitoring for tests
let testStartTime;

beforeEach(() => {
  testStartTime = Date.now();
});

afterEach(() => {
  const testDuration = Date.now() - testStartTime;
  
  // Warn about slow tests (over 5 seconds)
  if (testDuration > 5000) {
    console.warn(`⚠️ Slow test detected: ${testDuration}ms`);
  }
});

// Memory leak detection
const initialMemory = process.memoryUsage();

afterAll(() => {
  const finalMemory = process.memoryUsage();
  const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;
  
  // Warn about potential memory leaks (over 50MB increase)
  if (memoryIncrease > 50 * 1024 * 1024) {
    console.warn(`⚠️ Potential memory leak detected: ${Math.round(memoryIncrease / 1024 / 1024)}MB increase`);
  }
});

// Mock network requests to prevent external calls during tests
global.mockNetworkRequests = () => {
  // Mock fetch if available
  if (global.fetch) {
    global.fetch = jest.fn();
  }
  
  // Mock https.request for our HubSpot client
  const https = require('https');
  const originalRequest = https.request;
  
  https.request = jest.fn().mockImplementation((options, callback) => {
    // Create a mock response
    const mockResponse = {
      statusCode: 200,
      headers: { 'content-type': 'application/json' },
      on: jest.fn((event, handler) => {
        if (event === 'data') {
          handler(JSON.stringify({ results: [], total: 0 }));
        } else if (event === 'end') {
          handler();
        }
      })
    };
    
    // Create a mock request object
    const mockRequest = {
      on: jest.fn(),
      write: jest.fn(),
      end: jest.fn(() => {
        if (callback) callback(mockResponse);
      })
    };
    
    return mockRequest;
  });
  
  // Restore after tests
  afterAll(() => {
    https.request = originalRequest;
  });
};

// Export test utilities for use in test files
module.exports = {
  testUtils: global.testUtils,
  mockNetworkRequests: global.mockNetworkRequests
};
