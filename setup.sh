#!/bin/bash

# Setup script for GitHub Security Reporter
# This script prepares the environment and validates dependencies

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

echo "🔧 Setting up GitHub Security Reporter"
echo "======================================"

# Make main script executable
chmod +x github-security-reporter.sh
log_success "Made github-security-reporter.sh executable"

# Make test script executable
chmod +x tests/run-tests.sh
log_success "Made test script executable"

# Check dependencies
log_info "Checking dependencies..."

# Check for GitHub CLI
if command -v gh &> /dev/null; then
    log_success "GitHub CLI found"
    
    # Check authentication
    if gh auth status --hostname github.com &> /dev/null; then
        log_success "GitHub CLI authenticated"
    else
        log_info "GitHub CLI not authenticated - run 'gh auth login'"
    fi
else
    log_error "GitHub CLI not found"
    echo "Install from: https://cli.github.com/"
fi

# Check for jq
if command -v jq &> /dev/null; then
    log_success "jq found"
else
    log_error "jq not found"
    echo "Install with:"
    echo "  macOS: brew install jq"
    echo "  Ubuntu: sudo apt-get install jq"
    echo "  Other: https://stedolan.github.io/jq/download/"
fi

# Check for curl
if command -v curl &> /dev/null; then
    log_success "curl found"
else
    log_error "curl not found (usually pre-installed)"
fi

# Check for Node.js (optional)
if command -v node &> /dev/null; then
    log_success "Node.js found (for PDF generation)"
else
    log_info "Node.js not found (optional - for PDF generation)"
fi

# Check for PDF generation tools
pdf_tools=0
if command -v wkhtmltopdf &> /dev/null; then
    log_success "wkhtmltopdf found"
    ((pdf_tools++))
fi

if command -v google-chrome &> /dev/null || command -v chromium &> /dev/null || command -v chromium-browser &> /dev/null; then
    log_success "Chrome/Chromium found"
    ((pdf_tools++))
fi

if [[ $pdf_tools -eq 0 ]]; then
    log_info "No PDF generation tools found"
    log_info "Install wkhtmltopdf or Chrome for PDF reports"
fi

echo ""
echo "🎯 Quick Start:"
echo "  ./github-security-reporter.sh --help"
echo "  ./github-security-reporter.sh microsoft vscode"
echo ""
echo "🧪 Run Tests:"
echo "  ./tests/run-tests.sh"
echo ""
log_success "Setup complete!"