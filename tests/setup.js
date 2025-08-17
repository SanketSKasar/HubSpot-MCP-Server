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
process.env.HUBSPOT_PRIVATE_APP_ACCESS_TOKEN = 'test_token_for_jest';

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
   * Generate test MCP request data
   * @param {Object} overrides - Override default values
   * @returns {Object}
   */
  createMCPRequest: (overrides = {}) => {
    return {
      query: 'test query',
      context: {
        user: 'test-user',
        timestamp: new Date().toISOString(),
        ...overrides.context
      },
      ...overrides
    };
  },

  /**
   * Create mock response for testing
   * @param {Object} data - Response data
   * @returns {Object}
   */
  createMockResponse: (data = {}) => {
    return {
      status: 'success',
      timestamp: new Date().toISOString(),
      ...data
    };
  }
};

// Mock console methods in test environment to reduce noise
const originalConsole = global.console;
global.console = {
  ...originalConsole,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: originalConsole.error // Keep error logs for debugging failed tests
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
  
  // Reset modules if needed
  jest.resetModules();
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

// Mock external dependencies that we don't want to call during tests
jest.mock('@hubspot/mcp-server', () => ({
  // Mock implementation of HubSpot MCP server
  start: jest.fn().mockResolvedValue(true),
  stop: jest.fn().mockResolvedValue(true),
  process: jest.fn().mockImplementation((query, context) => {
    return Promise.resolve({
      status: 'success',
      result: `Processed: ${query}`,
      context
    });
  })
}));

// Mock Winston logger to prevent log files during tests
jest.mock('winston', () => {
  const mocked = {
    format: {
      combine: jest.fn(),
      timestamp: jest.fn(),
      errors: jest.fn(),
      json: jest.fn(),
      colorize: jest.fn(),
      simple: jest.fn()
    },
    createLogger: jest.fn(() => ({
      info: jest.fn(),
      warn: jest.fn(),
      error: jest.fn(),
      debug: jest.fn()
    })),
    transports: {
      Console: jest.fn(),
      File: jest.fn()
    }
  };
  return mocked;
});

// Performance monitoring for tests
let testStartTime;

beforeEach(() => {
  testStartTime = Date.now();
});

afterEach(() => {
  const testDuration = Date.now() - testStartTime;
  
  // Warn about slow tests
  if (testDuration > 5000) { // 5 seconds
    console.warn(`Slow test detected: ${testDuration}ms`);
  }
});

// Memory leak detection
const initialMemory = process.memoryUsage();

afterAll(() => {
  const finalMemory = process.memoryUsage();
  const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;
  
  // Warn about potential memory leaks
  if (memoryIncrease > 50 * 1024 * 1024) { // 50MB
    console.warn(`Potential memory leak detected: ${Math.round(memoryIncrease / 1024 / 1024)}MB increase`);
  }
});

// Test database setup (if needed in the future)
global.setupTestDatabase = async () => {
  // This would set up a test database if the application used one
  // For now, this is a placeholder for future expansion
};

global.teardownTestDatabase = async () => {
  // This would clean up the test database
  // For now, this is a placeholder for future expansion
};

// Export test utilities for use in test files
module.exports = {
  testUtils: global.testUtils,
  setupTestDatabase: global.setupTestDatabase,
  teardownTestDatabase: global.teardownTestDatabase
};
