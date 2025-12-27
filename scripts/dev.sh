#!/bin/bash
# Development helper script for PixlSrve

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${GREEN}===================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}===================================${NC}"
}

function print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

function build_host() {
    print_header "Building Host Application"
    cd "$PROJECT_ROOT/host"
    
    echo "Downloading dependencies..."
    go mod download
    
    echo "Building..."
    go build -o pixlsrve ./cmd/pixlsrve
    
    echo -e "${GREEN}✓ Host built successfully${NC}"
    echo "Binary: $PROJECT_ROOT/host/pixlsrve"
}

function run_host() {
    print_header "Running Host Application"
    cd "$PROJECT_ROOT/host"
    
    if [ ! -f "./pixlsrve" ]; then
        print_error "Host binary not found. Run './scripts/dev.sh build-host' first"
        exit 1
    fi
    
    ./pixlsrve "$@"
}

function show_help() {
    cat << EOF
PixlSrve Development Helper Script

Usage: ./scripts/dev.sh [command]

Commands:
    build-host          Build the host application
    run-host            Run the host application
    help                Show this help message

Examples:
    ./scripts/dev.sh build-host
    ./scripts/dev.sh run-host

EOF
}

# Main script logic
case "${1:-help}" in
    build-host)
        build_host
        ;;
    run-host)
        shift
        run_host "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
