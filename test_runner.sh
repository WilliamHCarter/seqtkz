#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}SeqtkZ Testing Framework${NC}"
echo "========================="

# Check if seqtk is installed
if ! command -v seqtk &> /dev/null; then
    echo -e "${RED}Error: seqtk is not installed or not in PATH${NC}"
    echo "Please install seqtk first:"
    echo "  - Ubuntu/Debian: sudo apt-get install seqtk"
    echo "  - macOS: brew install seqtk"
    echo "  - From source: https://github.com/lh3/seqtk"
    exit 1
fi

# Parse command line arguments
COMMAND=${1:-all}
VERBOSE=""
FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE="--verbose"
            shift
            ;;
        -f|--filter)
            FILTER="$2"
            shift 2
            ;;
        *)
            COMMAND=$1
            shift
            ;;
    esac
done

# Build the project first
echo -e "${YELLOW}Building seqtkz...${NC}"
zig build

case $COMMAND in
    unit)
        echo -e "${YELLOW}Running unit tests...${NC}"
        zig build test $VERBOSE
        ;;
    compare)
        echo -e "${YELLOW}Running comparison tests...${NC}"
        zig build test-compare $VERBOSE
        ;;
    bench)
        echo -e "${YELLOW}Running benchmarks...${NC}"
        zig build bench $VERBOSE
        ;;
    all)
        echo -e "${YELLOW}Running all tests...${NC}"
        zig build test-all $VERBOSE
        ;;
    quick)
        echo -e "${YELLOW}Running quick smoke tests...${NC}"
        # Test basic functionality
        echo ">test" | ./zig-out/bin/seqtkz size
        echo ">test\nAAAACCCCGGGGTTTT" | ./zig-out/bin/seqtkz hpc
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        echo "Usage: $0 [unit|compare|bench|all|quick] [-v|--verbose] [-f|--filter <pattern>]"
        exit 1
        ;;
esac

echo -e "${GREEN}Testing complete!${NC}"
