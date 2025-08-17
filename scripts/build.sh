#!/bin/bash

# =============================================================================
# HubSpot MCP Server Docker Build Script
# =============================================================================
#
# This script provides comprehensive Docker build functionality with:
# - Multi-stage builds for different environments
# - Security scanning and validation
# - Performance optimization
# - Build caching
# - Cross-platform building
#
# Usage:
#   ./scripts/build.sh [OPTIONS]
#
# Options:
#   -e, --env ENV         Build environment (dev, prod, test) [default: prod]
#   -t, --tag TAG         Docker image tag [default: latest]
#   -p, --push            Push image to registry after build
#   -s, --scan            Run security scan after build
#   -c, --clean           Clean build cache before building
#   -m, --multi-arch      Build for multiple architectures
#   -h, --help            Show this help message
#
# Examples:
#   ./scripts/build.sh                          # Build production image
#   ./scripts/build.sh -e dev -t my-tag         # Build development image
#   ./scripts/build.sh -p -s                    # Build, push, and scan
#   ./scripts/build.sh -m                       # Multi-architecture build
#
# =============================================================================

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
VERSION=$(grep '"version"' "$PROJECT_DIR/package.json" | sed 's/.*"version": "\([^"]*\)".*/\1/')

# Default values
ENVIRONMENT="prod"
TAG="latest"
PUSH=false
SCAN=false
CLEAN=false
MULTI_ARCH=false
REGISTRY_GHCR="ghcr.io"
REGISTRY_DOCKER="docker.io"
IMAGE_NAME="hubspot-mcp-server"
GITHUB_USERNAME_LOWER="sanketskasar"

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
HubSpot MCP Server Docker Build Script

Usage: $0 [OPTIONS]

Options:
    -e, --env ENV         Build environment (dev, prod, test) [default: prod]
    -t, --tag TAG         Docker image tag [default: latest]
    -p, --push            Push image to registry after build
    -s, --scan            Run security scan after build
    -c, --clean           Clean build cache before building
    -m, --multi-arch      Build for multiple architectures
    -h, --help            Show this help message

Examples:
    $0                          # Build production image
    $0 -e dev -t my-tag         # Build development image
    $0 -p -s                    # Build, push, and scan
    $0 -m                       # Multi-architecture build

Environment Variables:
    REGISTRY_GHCR       GitHub Container Registry [default: ghcr.io]
    REGISTRY_DOCKER     Docker Hub registry [default: docker.io]
    IMAGE_NAME          Image name [default: hubspot-mcp-server]
    DOCKER_USERNAME     Docker Hub username
    GITHUB_USERNAME     GitHub username

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            -p|--push)
                PUSH=true
                shift
                ;;
            -s|--scan)
                SCAN=true
                shift
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -m|--multi-arch)
                MULTI_ARCH=true
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
}

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|development)
            ENVIRONMENT="development"
            ;;
        prod|production)
            ENVIRONMENT="production"
            ;;
        test|testing)
            ENVIRONMENT="test"
            ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT"
            log_error "Valid environments: dev, prod, test"
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check Docker Buildx for multi-arch builds
    if [ "$MULTI_ARCH" = true ] && ! docker buildx version &> /dev/null; then
        log_error "Docker Buildx is required for multi-architecture builds"
        exit 1
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        log_warn "Git is not installed. Build metadata may be incomplete."
    fi
    
    log_success "Dependencies check completed"
}

# Clean build cache
clean_cache() {
    if [ "$CLEAN" = true ]; then
        log_info "Cleaning build cache..."
        docker builder prune -f
        docker system prune -f
        log_success "Build cache cleaned"
    fi
}

# Setup buildx for multi-arch
setup_buildx() {
    if [ "$MULTI_ARCH" = true ]; then
        log_info "Setting up Docker Buildx for multi-architecture build..."
        
        # Create and use a new builder instance
        docker buildx create --name multiarch-builder --use --bootstrap 2>/dev/null || \
        docker buildx use multiarch-builder
        
        # Inspect builder capabilities
        docker buildx inspect --bootstrap
        
        log_success "Docker Buildx configured for multi-architecture build"
    fi
}

# Generate build labels
generate_labels() {
    echo "--label org.opencontainers.image.created=\"$BUILD_DATE\" --label org.opencontainers.image.version=\"$VERSION\" --label org.opencontainers.image.revision=\"$GIT_COMMIT\" --label org.opencontainers.image.title=\"HubSpot MCP Server\" --label org.opencontainers.image.description=\"Docker container for HubSpot MCP Server\" --label org.opencontainers.image.source=\"https://github.com/${GITHUB_USERNAME:-SanketSKasar}/HubSpot-MCP-Server\" --label org.opencontainers.image.url=\"https://github.com/${GITHUB_USERNAME:-SanketSKasar}/HubSpot-MCP-Server\" --label org.opencontainers.image.vendor=\"Your Organization\" --label org.opencontainers.image.licenses=\"MIT\" --label org.opencontainers.image.documentation=\"https://github.com/${GITHUB_USERNAME:-SanketSKasar}/HubSpot-MCP-Server/blob/main/README.md\" --label maintainer=\"${MAINTAINER:-contact@yourdomain.com}\" --label build.environment=\"$ENVIRONMENT\" --label build.git-commit=\"$GIT_COMMIT\" --label build.date=\"$BUILD_DATE\""
}

# Build Docker image
build_image() {
    log_info "Building Docker image..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Tag: $TAG"
    log_info "Multi-arch: $MULTI_ARCH"
    
    local build_args=""
    local platforms=""
    local push_flag=""
    
    # Set platforms for multi-arch build
    if [ "$MULTI_ARCH" = true ]; then
        platforms="--platform linux/amd64,linux/arm64"
        push_flag="--push"  # Multi-arch builds require push
    fi
    
    # Set push flag if requested
    if [ "$PUSH" = true ] && [ "$MULTI_ARCH" = false ]; then
        push_flag="--push"
    fi
    
    # Generate image tags
    local ghcr_tag="${REGISTRY_GHCR}/${GITHUB_USERNAME_LOWER:-sanketskasar}/${IMAGE_NAME}:${TAG}"
    local docker_tag="${REGISTRY_DOCKER}/${DOCKER_USERNAME:-yourusername}/${IMAGE_NAME}:${TAG}"
    
    # Build command
    local build_cmd="docker buildx build"
    build_cmd="$build_cmd --target $ENVIRONMENT"
    build_cmd="$build_cmd --tag $ghcr_tag"
    
    # Add Docker Hub tag if username is provided
    if [ -n "${DOCKER_USERNAME:-}" ]; then
        build_cmd="$build_cmd --tag $docker_tag"
    fi
    
    build_cmd="$build_cmd $platforms"
    build_cmd="$build_cmd $(generate_labels)"
    build_cmd="$build_cmd --cache-from type=gha"
    build_cmd="$build_cmd --cache-to type=gha,mode=max"
    build_cmd="$build_cmd $push_flag"
    build_cmd="$build_cmd ."
    
    log_info "Build command: $build_cmd"
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    # Execute build
    if eval "$build_cmd"; then
        log_success "Docker image built successfully"
        log_info "Image tags:"
        log_info "  - $ghcr_tag"
        if [ -n "${DOCKER_USERNAME:-}" ]; then
            log_info "  - $docker_tag"
        fi
    else
        log_error "Docker build failed"
        exit 1
    fi
}

# Run security scan
run_security_scan() {
    if [ "$SCAN" = true ]; then
        log_info "Running security scan..."
        
        local image_tag="${REGISTRY_GHCR}/${GITHUB_USERNAME_LOWER:-sanketskasar}/${IMAGE_NAME}:${TAG}"
        
        # Run Trivy scan if available
        if command -v trivy &> /dev/null; then
            log_info "Running Trivy security scan..."
            trivy image --exit-code 1 --severity HIGH,CRITICAL "$image_tag"
        else
            log_warn "Trivy not found. Installing and running scan..."
            # Run Trivy in Docker
            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                -v "$HOME/.cache:/root/.cache" \
                aquasec/trivy:latest image \
                --exit-code 1 --severity HIGH,CRITICAL "$image_tag"
        fi
        
        log_success "Security scan completed"
    fi
}

# Test the built image
test_image() {
    log_info "Testing the built image..."
    
    local image_tag="${REGISTRY_GHCR}/${GITHUB_USERNAME_LOWER:-sanketskasar}/${IMAGE_NAME}:${TAG}"
    
    # Test 1: Container starts successfully
    log_info "Test 1: Container startup"
    if docker run --rm -d --name test-container \
        -e HUBSPOT_PRIVATE_APP_ACCESS_TOKEN=test_token \
        -p 13000:3000 \
        "$image_tag" > /dev/null; then
        
        # Wait for container to start
        sleep 5
        
        # Test health endpoint
        if curl -sf http://localhost:13000/health > /dev/null; then
            log_success "Health check passed"
        else
            log_error "Health check failed"
            docker logs test-container
            docker stop test-container
            exit 1
        fi
        
        # Stop test container
        docker stop test-container > /dev/null
        log_success "Container test passed"
    else
        log_error "Container failed to start"
        exit 1
    fi
    
    # Test 2: Image size check
    log_info "Test 2: Image size check"
    local image_size=$(docker images "$image_tag" --format "table {{.Size}}" | tail -n 1)
    log_info "Image size: $image_size"
    
    # Test 3: Security scan of built image
    if [ "$ENVIRONMENT" = "production" ]; then
        log_info "Test 3: Security validation for production image"
        # Additional security checks for production builds
        docker run --rm "$image_tag" whoami | grep -q nodejs || {
            log_error "Container not running as non-root user"
            exit 1
        }
        log_success "Security validation passed"
    fi
}

# Generate build summary
generate_summary() {
    log_info "Build Summary:"
    echo "============================================"
    echo "Environment:    $ENVIRONMENT"
    echo "Tag:           $TAG"
    echo "Version:       $VERSION"
    echo "Git Commit:    $GIT_COMMIT"
    echo "Build Date:    $BUILD_DATE"
    echo "Multi-arch:    $MULTI_ARCH"
    echo "Push:          $PUSH"
    echo "Scan:          $SCAN"
    echo "============================================"
}

# Main function
main() {
    log_info "Starting HubSpot MCP Server Docker build..."
    
    parse_args "$@"
    validate_environment
    check_dependencies
    clean_cache
    setup_buildx
    build_image
    
    # Only test if not doing multi-arch build (which requires push)
    if [ "$MULTI_ARCH" = false ]; then
        test_image
    fi
    
    run_security_scan
    generate_summary
    
    log_success "Build completed successfully!"
}

# Run main function with all arguments
main "$@"
