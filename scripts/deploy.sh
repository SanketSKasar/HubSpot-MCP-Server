#!/bin/bash

# =============================================================================
# HubSpot MCP Server Deployment Script
# =============================================================================
#
# This script provides comprehensive deployment functionality for various
# environments and platforms including:
# - Local Docker deployment
# - Docker Swarm deployment
# - Kubernetes deployment
# - Cloud platform deployment (AWS ECS, GCP Cloud Run, Azure Container Instances)
#
# Usage:
#   ./scripts/deploy.sh [OPTIONS]
#
# Options:
#   -p, --platform PLATFORM    Deployment platform (docker, swarm, k8s, aws, gcp, azure)
#   -e, --env ENV              Environment (dev, staging, prod) [default: prod]
#   -t, --tag TAG              Image tag [default: latest]
#   -c, --config CONFIG        Configuration file path
#   -n, --namespace NAMESPACE  Kubernetes namespace [default: default]
#   -r, --replicas COUNT       Number of replicas [default: 1]
#   -d, --dry-run              Show what would be deployed without executing
#   -h, --help                 Show this help message
#
# Examples:
#   ./scripts/deploy.sh -p docker                    # Local Docker deployment
#   ./scripts/deploy.sh -p k8s -e prod -r 3         # Kubernetes production deployment
#   ./scripts/deploy.sh -p aws -e staging           # AWS ECS staging deployment
#   ./scripts/deploy.sh -d                          # Dry run
#
# =============================================================================

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
PLATFORM=""
ENVIRONMENT="prod"
TAG="latest"
CONFIG_FILE=""
NAMESPACE="default"
REPLICAS=1
DRY_RUN=false
IMAGE_NAME="hubspot-mcp-server"
REGISTRY="ghcr.io"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
HubSpot MCP Server Deployment Script

Usage: $0 [OPTIONS]

Options:
    -p, --platform PLATFORM    Deployment platform (docker, swarm, k8s, aws, gcp, azure)
    -e, --env ENV              Environment (dev, staging, prod) [default: prod]
    -t, --tag TAG              Image tag [default: latest]
    -c, --config CONFIG        Configuration file path
    -n, --namespace NAMESPACE  Kubernetes namespace [default: default]
    -r, --replicas COUNT       Number of replicas [default: 1]
    -d, --dry-run              Show what would be deployed without executing
    -h, --help                 Show this help message

Platforms:
    docker    Local Docker deployment
    swarm     Docker Swarm deployment
    k8s       Kubernetes deployment
    aws       AWS ECS deployment
    gcp       Google Cloud Run deployment
    azure     Azure Container Instances deployment

Examples:
    $0 -p docker                    # Local Docker deployment
    $0 -p k8s -e prod -r 3         # Kubernetes production deployment
    $0 -p aws -e staging           # AWS ECS staging deployment
    $0 -d                          # Dry run

Environment Variables:
    REGISTRY            Container registry [default: ghcr.io]
    GITHUB_USERNAME     GitHub username for GHCR
    DOCKER_USERNAME     Docker Hub username
    AWS_REGION          AWS region for ECS deployment
    GCP_PROJECT         GCP project ID for Cloud Run
    AZURE_RESOURCE_GROUP Azure resource group

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -r|--replicas)
                REPLICAS="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Require platform
    if [ -z "$PLATFORM" ]; then
        log_error "Platform is required. Use -p or --platform to specify."
        show_help
        exit 1
    fi
}

# Validate platform
validate_platform() {
    case $PLATFORM in
        docker|swarm|k8s|kubernetes|aws|gcp|azure)
            if [ "$PLATFORM" = "kubernetes" ]; then
                PLATFORM="k8s"
            fi
            ;;
        *)
            log_error "Invalid platform: $PLATFORM"
            log_error "Valid platforms: docker, swarm, k8s, aws, gcp, azure"
            exit 1
            ;;
    esac
}

# Check platform-specific dependencies
check_dependencies() {
    log_info "Checking dependencies for platform: $PLATFORM"
    
    # Common dependencies
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Platform-specific dependencies
    case $PLATFORM in
        swarm)
            if ! docker node ls &> /dev/null; then
                log_error "Docker Swarm is not initialized. Run 'docker swarm init' first."
                exit 1
            fi
            ;;
        k8s)
            if ! command -v kubectl &> /dev/null; then
                log_error "kubectl is not installed or not in PATH"
                exit 1
            fi
            if ! kubectl cluster-info &> /dev/null; then
                log_error "kubectl is not connected to a Kubernetes cluster"
                exit 1
            fi
            ;;
        aws)
            if ! command -v aws &> /dev/null; then
                log_error "AWS CLI is not installed or not in PATH"
                exit 1
            fi
            if ! aws sts get-caller-identity &> /dev/null; then
                log_error "AWS CLI is not configured or credentials are invalid"
                exit 1
            fi
            ;;
        gcp)
            if ! command -v gcloud &> /dev/null; then
                log_error "Google Cloud SDK is not installed or not in PATH"
                exit 1
            fi
            if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
                log_error "Google Cloud SDK is not authenticated"
                exit 1
            fi
            ;;
        azure)
            if ! command -v az &> /dev/null; then
                log_error "Azure CLI is not installed or not in PATH"
                exit 1
            fi
            if ! az account show &> /dev/null; then
                log_error "Azure CLI is not authenticated"
                exit 1
            fi
            ;;
    esac
    
    log_success "Dependencies check completed"
}

# Generate deployment configuration
generate_config() {
    local config_dir="$PROJECT_DIR/deployment"
    mkdir -p "$config_dir"
    
    case $PLATFORM in
        docker)
            generate_docker_config "$config_dir"
            ;;
        swarm)
            generate_swarm_config "$config_dir"
            ;;
        k8s)
            generate_k8s_config "$config_dir"
            ;;
        aws)
            generate_aws_config "$config_dir"
            ;;
        gcp)
            generate_gcp_config "$config_dir"
            ;;
        azure)
            generate_azure_config "$config_dir"
            ;;
    esac
}

# Docker deployment configuration
generate_docker_config() {
    local config_dir="$1"
    local config_file="$config_dir/docker-run.sh"
    
    cat > "$config_file" << EOF
#!/bin/bash
# Generated Docker run configuration for $ENVIRONMENT environment

docker run -d \\
    --name hubspot-mcp-server-$ENVIRONMENT \\
    --restart unless-stopped \\
    -p 3000:3000 \\
    -e NODE_ENV=$ENVIRONMENT \\
    -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=\${HUBSPOT_PRIVATE_APP_ACCESS_TOKEN} \\
    -e LOG_LEVEL=info \\
    -e CORS_ORIGIN=\${CORS_ORIGIN:-*} \\
    --memory=512m \\
    --cpus=0.5 \\
    --read-only \\
    --tmpfs /tmp:noexec,nosuid,size=100m \\
    --tmpfs /var/log/app:nosuid,size=50m \\
    -v hubspot-mcp-logs-$ENVIRONMENT:/var/log/app \\
    $REGISTRY/\${GITHUB_USERNAME:-yourusername}/$IMAGE_NAME:$TAG
EOF
    
    chmod +x "$config_file"
    echo "$config_file"
}

# Docker Swarm deployment configuration
generate_swarm_config() {
    local config_dir="$1"
    local config_file="$config_dir/docker-stack.yml"
    
    cat > "$config_file" << EOF
version: '3.8'

services:
  hubspot-mcp-server:
    image: $REGISTRY/\${GITHUB_USERNAME:-yourusername}/$IMAGE_NAME:$TAG
    deploy:
      replicas: $REPLICAS
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
    environment:
      - NODE_ENV=$ENVIRONMENT
      - LOG_LEVEL=info
    secrets:
      - hubspot_token
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    networks:
      - hubspot-mcp-network

secrets:
  hubspot_token:
    external: true

networks:
  hubspot-mcp-network:
    driver: overlay
    attachable: true
EOF
    
    echo "$config_file"
}

# Kubernetes deployment configuration
generate_k8s_config() {
    local config_dir="$1"
    local config_file="$config_dir/k8s-deployment.yaml"
    
    cat > "$config_file" << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
---
apiVersion: v1
kind: Secret
metadata:
  name: hubspot-mcp-secrets
  namespace: $NAMESPACE
type: Opaque
data:
  hubspot-token: # Base64 encoded token - set this before applying
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hubspot-mcp-server
  namespace: $NAMESPACE
  labels:
    app: hubspot-mcp-server
    environment: $ENVIRONMENT
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: hubspot-mcp-server
  template:
    metadata:
      labels:
        app: hubspot-mcp-server
        environment: $ENVIRONMENT
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        runAsGroup: 1001
        fsGroup: 1001
      containers:
      - name: hubspot-mcp-server
        image: $REGISTRY/\${GITHUB_USERNAME:-yourusername}/$IMAGE_NAME:$TAG
        ports:
        - containerPort: 3000
          protocol: TCP
        env:
        - name: NODE_ENV
          value: "$ENVIRONMENT"
        - name: LOG_LEVEL
          value: "info"
        - name: HUBSPOT_PRIVATE_APP_ACCESS_TOKEN
          valueFrom:
            secretKeyRef:
              name: hubspot-mcp-secrets
              key: hubspot-token
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
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
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: logs
          mountPath: /var/log/app
      volumes:
      - name: tmp
        emptyDir: {}
      - name: logs
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: hubspot-mcp-service
  namespace: $NAMESPACE
  labels:
    app: hubspot-mcp-server
spec:
  selector:
    app: hubspot-mcp-server
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hubspot-mcp-ingress
  namespace: $NAMESPACE
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
              number: 80
EOF
    
    echo "$config_file"
}

# AWS ECS deployment configuration
generate_aws_config() {
    local config_dir="$1"
    local config_file="$config_dir/aws-task-definition.json"
    
    cat > "$config_file" << EOF
{
  "family": "hubspot-mcp-server",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::\${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::\${AWS_ACCOUNT_ID}:role/hubspot-mcp-task-role",
  "containerDefinitions": [
    {
      "name": "hubspot-mcp-server",
      "image": "$REGISTRY/\${GITHUB_USERNAME:-yourusername}/$IMAGE_NAME:$TAG",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "$ENVIRONMENT"
        },
        {
          "name": "LOG_LEVEL",
          "value": "info"
        }
      ],
      "secrets": [
        {
          "name": "HUBSPOT_PRIVATE_APP_ACCESS_TOKEN",
          "valueFrom": "arn:aws:secretsmanager:\${AWS_REGION}:\${AWS_ACCOUNT_ID}:secret:hubspot-mcp/token"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/hubspot-mcp-server",
          "awslogs-region": "\${AWS_REGION}",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      },
      "essential": true
    }
  ]
}
EOF
    
    echo "$config_file"
}

# Google Cloud Run deployment configuration
generate_gcp_config() {
    local config_dir="$1"
    local config_file="$config_dir/gcp-cloud-run.yaml"
    
    cat > "$config_file" << EOF
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hubspot-mcp-server
  annotations:
    run.googleapis.com/ingress: all
    run.googleapis.com/execution-environment: gen2
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/maxScale: "10"
        autoscaling.knative.dev/minScale: "0"
        run.googleapis.com/cpu-throttling: "true"
        run.googleapis.com/memory: "512Mi"
        run.googleapis.com/cpu: "1000m"
    spec:
      containerConcurrency: 80
      timeoutSeconds: 300
      containers:
      - image: $REGISTRY/\${GITHUB_USERNAME:-yourusername}/$IMAGE_NAME:$TAG
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "$ENVIRONMENT"
        - name: LOG_LEVEL
          value: "info"
        - name: HUBSPOT_PRIVATE_APP_ACCESS_TOKEN
          valueFrom:
            secretKeyRef:
              key: latest
              name: hubspot-token
        resources:
          limits:
            memory: "512Mi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        startupProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 5
          failureThreshold: 30
EOF
    
    echo "$config_file"
}

# Azure Container Instances deployment configuration
generate_azure_config() {
    local config_dir="$1"
    local config_file="$config_dir/azure-container.json"
    
    cat > "$config_file" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "containerGroupName": {
      "type": "string",
      "defaultValue": "hubspot-mcp-server-$ENVIRONMENT"
    },
    "hubspotToken": {
      "type": "securestring"
    }
  },
  "resources": [
    {
      "type": "Microsoft.ContainerInstance/containerGroups",
      "apiVersion": "2021-03-01",
      "name": "[parameters('containerGroupName')]",
      "location": "[resourceGroup().location]",
      "properties": {
        "containers": [
          {
            "name": "hubspot-mcp-server",
            "properties": {
              "image": "$REGISTRY/\${GITHUB_USERNAME:-yourusername}/$IMAGE_NAME:$TAG",
              "ports": [
                {
                  "port": 3000,
                  "protocol": "TCP"
                }
              ],
              "environmentVariables": [
                {
                  "name": "NODE_ENV",
                  "value": "$ENVIRONMENT"
                },
                {
                  "name": "LOG_LEVEL",
                  "value": "info"
                },
                {
                  "name": "HUBSPOT_PRIVATE_APP_ACCESS_TOKEN",
                  "secureValue": "[parameters('hubspotToken')]"
                }
              ],
              "resources": {
                "requests": {
                  "cpu": 0.5,
                  "memoryInGB": 0.5
                }
              },
              "livenessProbe": {
                "httpGet": {
                  "path": "/health",
                  "port": 3000
                },
                "initialDelaySeconds": 30,
                "periodSeconds": 10
              }
            }
          }
        ],
        "osType": "Linux",
        "ipAddress": {
          "type": "Public",
          "ports": [
            {
              "protocol": "TCP",
              "port": 3000
            }
          ]
        },
        "restartPolicy": "OnFailure"
      }
    }
  ],
  "outputs": {
    "containerIPv4Address": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.ContainerInstance/containerGroups', parameters('containerGroupName'))).ipAddress.ip]"
    }
  }
}
EOF
    
    echo "$config_file"
}

# Execute deployment
execute_deployment() {
    local config_file="$1"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would execute deployment with configuration:"
        cat "$config_file"
        return 0
    fi
    
    case $PLATFORM in
        docker)
            log_info "Deploying to Docker..."
            bash "$config_file"
            ;;
        swarm)
            log_info "Deploying to Docker Swarm..."
            docker stack deploy -c "$config_file" hubspot-mcp-stack
            ;;
        k8s)
            log_info "Deploying to Kubernetes..."
            kubectl apply -f "$config_file"
            ;;
        aws)
            log_info "Deploying to AWS ECS..."
            # Register task definition and update service
            aws ecs register-task-definition --cli-input-json "file://$config_file"
            ;;
        gcp)
            log_info "Deploying to Google Cloud Run..."
            gcloud run services replace "$config_file" \
                --region="${GCP_REGION:-us-central1}" \
                --project="${GCP_PROJECT}"
            ;;
        azure)
            log_info "Deploying to Azure Container Instances..."
            az deployment group create \
                --resource-group "${AZURE_RESOURCE_GROUP}" \
                --template-file "$config_file" \
                --parameters hubspotToken="${HUBSPOT_PRIVATE_APP_ACCESS_TOKEN}"
            ;;
    esac
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    case $PLATFORM in
        docker)
            if docker ps | grep -q hubspot-mcp-server-$ENVIRONMENT; then
                log_success "Docker deployment verified"
            else
                log_error "Docker deployment verification failed"
                exit 1
            fi
            ;;
        swarm)
            if docker service ls | grep -q hubspot-mcp-stack; then
                log_success "Docker Swarm deployment verified"
            else
                log_error "Docker Swarm deployment verification failed"
                exit 1
            fi
            ;;
        k8s)
            kubectl wait --for=condition=available --timeout=300s \
                deployment/hubspot-mcp-server -n "$NAMESPACE"
            log_success "Kubernetes deployment verified"
            ;;
        aws|gcp|azure)
            log_info "Cloud deployment initiated. Check cloud console for status."
            ;;
    esac
}

# Main function
main() {
    log_info "Starting HubSpot MCP Server deployment..."
    
    parse_args "$@"
    validate_platform
    check_dependencies
    
    log_info "Generating deployment configuration..."
    config_file=$(generate_config)
    
    log_info "Generated configuration file: $config_file"
    
    execute_deployment "$config_file"
    
    if [ "$DRY_RUN" = false ]; then
        verify_deployment
        log_success "Deployment completed successfully!"
    else
        log_info "Dry run completed. No actual deployment was performed."
    fi
}

# Run main function with all arguments
main "$@"
