# Contributing to HubSpot MCP Server Docker Container

🎉 **Thank you for your interest in contributing!** 🎉

This document provides guidelines and information for contributing to the HubSpot MCP Server Docker Container project. We welcome contributions of all kinds, from bug reports and feature requests to code contributions and documentation improvements.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Community](#community)

## 🤝 Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## 🚀 How to Contribute

### 🐛 Reporting Bugs

Before creating bug reports, please check the [issue list](https://github.com/yourusername/hubspot-mcp-server-docker/issues) to see if the problem has already been reported.

**Great Bug Reports** include:

- **Clear title** that summarizes the issue
- **Detailed description** of the problem
- **Steps to reproduce** the behavior
- **Expected vs. actual behavior**
- **Environment information** (OS, Docker version, etc.)
- **Screenshots or logs** if applicable
- **Possible solutions** if you have ideas

#### Bug Report Template

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run command '...'
2. Set environment variable '...'
3. Access endpoint '...'
4. See error

**Expected behavior**
A clear description of what you expected to happen.

**Environment:**
- OS: [e.g., Ubuntu 20.04]
- Docker version: [e.g., 20.10.0]
- Container image: [e.g., ghcr.io/yourusername/hubspot-mcp-server:1.0.0]
- Node.js version: [if running locally]

**Additional context**
Add any other context about the problem here.
```

### 💡 Suggesting Features

We love feature suggestions! Feature requests help us understand what would be valuable to users.

**Great Feature Requests** include:

- **Clear title** that summarizes the feature
- **Detailed description** of the proposed functionality
- **Use case** explaining why this would be useful
- **Proposed solution** if you have implementation ideas
- **Alternatives considered** and why they weren't suitable

#### Feature Request Template

```markdown
**Feature Description**
A clear and concise description of what you want to happen.

**Use Case**
Describe the use case and why this feature would be valuable.

**Proposed Solution**
Describe how you envision this feature working.

**Alternatives Considered**
Describe any alternative solutions you've considered.

**Additional Context**
Add any other context or screenshots about the feature request.
```

### 📝 Improving Documentation

Documentation improvements are always welcome! This includes:

- README updates
- API documentation
- Code comments
- Deployment guides
- Troubleshooting guides
- Example configurations

## 🛠️ Development Setup

### Prerequisites

- **Node.js** 20.10.0 or later
- **Docker** 20.10 or later
- **Git** for version control
- **npm** or **yarn** for package management

### Local Development Environment

1. **Fork and Clone the Repository**
   ```bash
   # Fork the repository on GitHub, then clone your fork
   git clone https://github.com/yourusername/hubspot-mcp-server-docker.git
   cd hubspot-mcp-server-docker
   
   # Add upstream remote
   git remote add upstream https://github.com/originalusername/hubspot-mcp-server-docker.git
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Set Up Environment**
   ```bash
   # Copy example environment file
   cp env.example .env
   
   # Edit .env with your HubSpot token and configuration
   nano .env
   ```

4. **Start Development Server**
   ```bash
   # Run locally
   npm run dev
   
   # Or use Docker development environment
   docker-compose --profile dev up
   ```

### Docker Development

Build and test your changes:

```bash
# Build development image
docker build --target development -t hubspot-mcp-server:dev .

# Build production image
docker build --target production -t hubspot-mcp-server:prod .

# Run tests in container
docker-compose --profile test up --abort-on-container-exit

# Run security scan
docker-compose --profile security up --abort-on-container-exit
```

## 🔄 Pull Request Process

### Before You Start

1. **Check existing issues** and pull requests to avoid duplicates
2. **Create an issue** to discuss major changes before implementing
3. **Fork the repository** and create a feature branch
4. **Keep changes focused** - one feature or fix per PR

### Creating a Pull Request

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make Your Changes**
   - Follow the [coding standards](#coding-standards)
   - Add tests for new functionality
   - Update documentation as needed
   - Ensure all tests pass

3. **Commit Your Changes**
   ```bash
   # Use conventional commits format
   git add .
   git commit -m "feat: add new feature description"
   # or
   git commit -m "fix: resolve issue with specific component"
   ```

4. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**
   - Go to GitHub and create a pull request
   - Fill out the pull request template
   - Link any related issues
   - Request review from maintainers

### Pull Request Template

```markdown
## Description
Brief description of the changes and why they were made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Related Issues
Fixes #(issue number)

## Testing
- [ ] Tests pass locally
- [ ] Added tests for new functionality
- [ ] Manual testing completed

## Security Considerations
- [ ] No sensitive information exposed
- [ ] Security best practices followed
- [ ] Security review completed (if applicable)

## Documentation
- [ ] README updated
- [ ] API documentation updated
- [ ] Configuration documentation updated

## Checklist
- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

### Review Process

1. **Automated Checks**: All CI/CD checks must pass
2. **Code Review**: At least one maintainer will review your PR
3. **Testing**: Changes will be tested in various environments
4. **Documentation**: Documentation must be updated for new features
5. **Approval**: Maintainer approval required before merging

## 🎨 Coding Standards

### JavaScript/Node.js Style

We use ESLint with specific configurations:

```bash
# Check linting
npm run lint

# Fix linting issues
npm run lint:fix
```

#### Key Principles

- **Consistency**: Follow existing code patterns
- **Readability**: Write self-documenting code
- **Security**: Follow security best practices
- **Performance**: Consider performance implications
- **Maintainability**: Write code that's easy to maintain

#### Code Formatting

- **Indentation**: 2 spaces (no tabs)
- **Quotes**: Single quotes for strings
- **Semicolons**: Always use semicolons
- **Line length**: Max 100 characters
- **Trailing commas**: Use in multi-line structures

#### Example Code Style

```javascript
'use strict';

const express = require('express');
const { validationResult } = require('express-validator');
const logger = require('./utils/logger');

/**
 * Handle MCP requests with proper error handling
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @returns {Promise<void>}
 */
async function handleMCPRequest(req, res) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { query, context = {} } = req.body;
    
    logger.info('Processing MCP request', { 
      queryLength: query.length,
      contextKeys: Object.keys(context)
    });

    const result = await processRequest(query, context);
    
    res.json({
      status: 'success',
      timestamp: new Date().toISOString(),
      result
    });
    
  } catch (error) {
    logger.error('MCP request failed:', error);
    res.status(500).json({
      status: 'error',
      message: 'Internal server error'
    });
  }
}
```

### Docker Best Practices

- **Multi-stage builds**: Use for optimization
- **Security scanning**: Include security checks
- **Minimal images**: Use Alpine Linux base
- **Non-root user**: Always run as non-root
- **Layer optimization**: Minimize layers and image size

### Documentation Standards

- **Code comments**: Explain complex logic
- **JSDoc**: Use for function documentation
- **README sections**: Keep organized and up-to-date
- **Inline documentation**: Explain configuration options
- **Examples**: Provide practical examples

## 🧪 Testing Guidelines

### Test Types

1. **Unit Tests**: Test individual functions and modules
2. **Integration Tests**: Test component interactions
3. **Container Tests**: Test Docker container functionality
4. **Security Tests**: Test security configurations
5. **Performance Tests**: Test under load (for major changes)

### Writing Tests

```javascript
// Example unit test
const { processRequest } = require('../src/mcp-handler');

describe('MCP Handler', () => {
  describe('processRequest', () => {
    it('should handle valid requests', async () => {
      const query = 'test query';
      const context = { user: 'test' };
      
      const result = await processRequest(query, context);
      
      expect(result).toBeDefined();
      expect(result.status).toBe('success');
    });

    it('should reject invalid queries', async () => {
      const query = '';
      const context = {};
      
      await expect(processRequest(query, context))
        .rejects
        .toThrow('Invalid query');
    });
  });
});
```

### Test Commands

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- src/tests/mcp-handler.test.js

# Run tests in watch mode
npm run test:watch

# Run integration tests
npm run test:integration
```

### Test Requirements

- **Coverage**: Aim for >80% code coverage
- **Edge cases**: Test error conditions
- **Security**: Test security configurations
- **Performance**: Test with realistic data sizes
- **Documentation**: Document complex test scenarios

## 📚 Documentation

### Documentation Types

1. **Code Documentation**: JSDoc comments, inline comments
2. **API Documentation**: Endpoint descriptions and examples
3. **User Documentation**: README, usage guides
4. **Developer Documentation**: Contributing guides, architecture docs
5. **Deployment Documentation**: Docker, Kubernetes, cloud deployment guides

### Documentation Standards

- **Clarity**: Write for your audience
- **Accuracy**: Keep documentation up-to-date
- **Examples**: Provide practical examples
- **Structure**: Use consistent formatting
- **Accessibility**: Consider different skill levels

### Documentation Checklist

- [ ] **README updated** with new features
- [ ] **API docs updated** for new endpoints
- [ ] **Configuration docs updated** for new options
- [ ] **Examples provided** for new functionality
- [ ] **Troubleshooting updated** for known issues

## 🌟 Recognition

We believe in recognizing contributions! Contributors will be:

- **Listed in CONTRIBUTORS.md**
- **Mentioned in release notes** for significant contributions
- **Given credit in commit messages** and pull requests
- **Invited to be maintainers** for sustained contributions

### Types of Contributions We Value

- 🐛 **Bug fixes** - Help keep the project stable
- ✨ **New features** - Expand functionality
- 📚 **Documentation** - Help others use the project
- 🧪 **Tests** - Improve code quality
- 🔒 **Security** - Keep the project secure
- 🎨 **UI/UX** - Improve user experience
- 🚀 **Performance** - Make things faster
- 🔧 **DevOps** - Improve development workflow

## 💬 Community

### Getting Help

- **GitHub Discussions**: For questions and general discussion
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: Check existing docs first
- **Stack Overflow**: Tag questions with `hubspot-mcp-server`

### Communication Guidelines

- **Be respectful** and inclusive
- **Provide context** when asking questions
- **Search existing issues** before creating new ones
- **Use clear titles** and descriptions
- **Follow up** on your issues and PRs

### Maintainer Response Times

- **Bug reports**: Within 48 hours
- **Feature requests**: Within 1 week
- **Pull requests**: Within 1 week
- **Security issues**: Within 24 hours

## 📞 Contact

- **Project Maintainers**: @maintainer1, @maintainer2
- **Security Issues**: security@yourdomain.com
- **General Questions**: Create a GitHub Discussion

---

**Thank you for contributing to making this project better for everyone!** 🙏

Your contributions, whether big or small, help make this project successful and valuable to the community.
