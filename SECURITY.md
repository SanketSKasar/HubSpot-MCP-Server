# Security Policy

## 🔒 Security Overview

The HubSpot MCP Server Docker container is designed with security as a primary concern. This document outlines our security practices, how to report vulnerabilities, and security best practices for deployment.

## 🛡️ Security Features

### Container Security

- **Non-root execution**: Container runs as unprivileged user `nodejs` (UID 1001)
- **Read-only filesystem**: Root filesystem is mounted read-only
- **Minimal base image**: Alpine Linux with only essential packages
- **Security scanning**: Automated vulnerability scanning with Trivy
- **Regular updates**: Automated dependency updates and security patches

### Application Security

- **Rate limiting**: Configurable request rate limiting to prevent abuse
- **CORS protection**: Cross-Origin Resource Sharing controls
- **Security headers**: Comprehensive HTTP security headers via Helmet.js
- **Input validation**: Request validation and sanitization
- **Error handling**: Secure error responses without information disclosure
- **Audit logging**: Comprehensive audit trail for security events

### Network Security

- **TLS/SSL support**: HTTPS configuration for production deployments
- **Network policies**: Kubernetes network policy examples
- **Firewall rules**: Recommended firewall configurations
- **Port exposure**: Minimal port exposure (only application port)

## 🔐 Secrets Management

### Environment Variables

Never include sensitive information in:
- Docker images
- Source code
- Configuration files committed to version control
- Container environment variables in plain text

### Recommended Approaches

#### Docker Secrets (Docker Swarm)
```bash
# Create secret
echo "your_hubspot_token" | docker secret create hubspot_token -

# Use in service
docker service create \
  --name hubspot-mcp \
  --secret hubspot_token \
  --env HUBSPOT_PRIVATE_APP_ACCESS_TOKEN_FILE=/run/secrets/hubspot_token \
  ghcr.io/yourusername/hubspot-mcp-server
```

#### Kubernetes Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: hubspot-mcp-secrets
type: Opaque
data:
  hubspot-token: <base64-encoded-token>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hubspot-mcp-server
spec:
  template:
    spec:
      containers:
      - name: hubspot-mcp
        env:
        - name: HUBSPOT_PRIVATE_APP_ACCESS_TOKEN
          valueFrom:
            secretKeyRef:
              name: hubspot-mcp-secrets
              key: hubspot-token
```

#### AWS Secrets Manager
```bash
# Store secret
aws secretsmanager create-secret \
  --name hubspot-mcp/token \
  --description "HubSpot Private App Access Token" \
  --secret-string "your_hubspot_token"

# Use with ECS task definition
{
  "secrets": [
    {
      "name": "HUBSPOT_PRIVATE_APP_ACCESS_TOKEN",
      "valueFrom": "arn:aws:secretsmanager:region:account:secret:hubspot-mcp/token"
    }
  ]
}
```

## 🚨 Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## 🐛 Reporting a Vulnerability

We take security vulnerabilities seriously. Please follow responsible disclosure practices.

### How to Report

1. **GitHub Security Advisories** (Preferred)
   - Go to the [Security tab](https://github.com/yourusername/hubspot-mcp-server-docker/security/advisories)
   - Click "New draft security advisory"
   - Provide detailed information about the vulnerability

2. **Email** (For sensitive issues)
   - Send email to: security@yourdomain.com
   - Use GPG encryption if possible
   - Include "SECURITY" in the subject line

### What to Include

Please provide the following information:

- **Description**: Clear description of the vulnerability
- **Impact**: Potential impact and severity assessment
- **Reproduction**: Step-by-step reproduction instructions
- **Environment**: Affected versions and configurations
- **Proof of Concept**: Code or commands demonstrating the issue
- **Suggested Fix**: If you have suggestions for remediation

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Progress Updates**: Weekly until resolution
- **Resolution**: Target 30 days for critical issues, 90 days for others

### Disclosure Policy

- We will work with you to understand and validate the report
- We will develop and test a fix
- We will coordinate disclosure timing with you
- We will credit you in the security advisory (unless you prefer anonymity)
- We may offer recognition through our security researcher program

## 🛠️ Security Best Practices

### Deployment Security

#### Production Checklist

- [ ] **Use specific image tags** (avoid `latest` in production)
- [ ] **Enable read-only filesystem**
- [ ] **Configure resource limits**
- [ ] **Use secrets management**
- [ ] **Enable security scanning**
- [ ] **Configure network policies**
- [ ] **Enable audit logging**
- [ ] **Set up monitoring and alerting**

#### Docker Security

```bash
# Secure Docker run command
docker run -d \
  --name hubspot-mcp-server \
  --user 1001:1001 \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=100m \
  --tmpfs /var/log/app:nosuid,size=50m \
  --cap-drop ALL \
  --cap-add CHOWN \
  --cap-add SETGID \
  --cap-add SETUID \
  --security-opt no-new-privileges:true \
  --memory=512m \
  --cpus=0.5 \
  -p 3000:3000 \
  ghcr.io/yourusername/hubspot-mcp-server:1.0.0
```

#### Kubernetes Security

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      containers:
      - name: hubspot-mcp
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
            add:
            - CHOWN
            - SETGID
            - SETUID
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
```

### Network Security

#### Firewall Rules

```bash
# Allow only necessary ports
ufw allow 3000/tcp  # Application port
ufw deny 22/tcp     # SSH (use alternative port)
ufw enable
```

#### TLS Configuration

```yaml
# Ingress with TLS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hubspot-mcp-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - api.yourdomain.com
    secretName: tls-secret
  rules:
  - host: api.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hubspot-mcp-service
            port:
              number: 3000
```

### Application Security

#### Environment Configuration

```bash
# Production security configuration
NODE_ENV=production
LOG_LEVEL=warn
CORS_ORIGIN=https://yourdomain.com,https://app.yourdomain.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
ENABLE_HELMET=true
ENABLE_COMPRESSION=true
```

#### Monitoring and Alerting

```yaml
# Security monitoring alerts
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: High error rate detected

- alert: SecurityViolation
  expr: rate(security_violations_total[5m]) > 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: Security violation detected
```

## 📊 Security Monitoring

### Audit Logging

The application logs security-relevant events:

- Authentication attempts
- Authorization failures
- Rate limit violations
- Suspicious request patterns
- Configuration changes

### Metrics

Security metrics exposed for monitoring:

- `http_requests_total` - Total HTTP requests by status code
- `rate_limit_violations_total` - Rate limit violations
- `auth_failures_total` - Authentication failures
- `security_headers_sent_total` - Security headers sent

### Log Analysis

Example log entries for security events:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "warn",
  "message": "Rate limit exceeded",
  "ip": "192.168.1.100",
  "userAgent": "curl/7.68.0",
  "endpoint": "/mcp",
  "rateLimitWindow": "15m",
  "requestCount": 101,
  "maxRequests": 100
}
```

## 🔍 Security Scanning

### Automated Scanning

The project includes automated security scanning:

```bash
# Container vulnerability scanning
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  ghcr.io/yourusername/hubspot-mcp-server:latest

# Dependency scanning
npm audit --audit-level=moderate

# SAST (Static Application Security Testing)
npm run security-scan
```

### Manual Security Review

Regular manual security reviews should include:

- Code review for security issues
- Configuration review
- Infrastructure review
- Third-party dependency review
- Penetration testing (for critical deployments)

## 📚 Security Resources

### Educational Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

### Security Tools

- [Trivy](https://github.com/aquasecurity/trivy) - Container vulnerability scanner
- [Hadolint](https://github.com/hadolint/hadolint) - Dockerfile linter
- [npm audit](https://docs.npmjs.com/cli/v8/commands/npm-audit) - Dependency vulnerability scanner
- [ESLint Security Plugin](https://github.com/nodesecurity/eslint-plugin-security) - Security linting

## 📞 Contact

For security-related questions or concerns:

- **Security Team**: security@yourdomain.com
- **General Contact**: support@yourdomain.com
- **GitHub Issues**: For non-security related issues only

---

**Remember**: Security is everyone's responsibility. Help us keep this project secure by following these guidelines and reporting any security concerns promptly.
