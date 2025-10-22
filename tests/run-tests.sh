#!/bin/bash

# Test suite for GitHub Security Reporter
# Run basic functionality tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT="$ROOT_DIR/github-security-reporter.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Logging functions
log_test() {
    echo -e "${YELLOW}Testing:${NC} $1"
    ((TESTS_RUN++))
}

log_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
}

log_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Test script exists and is executable
test_script_exists() {
    log_test "Script exists and is executable"
    if [[ -f "$SCRIPT" && -x "$SCRIPT" ]]; then
        log_pass "Script found and executable"
    else
        log_fail "Script not found or not executable"
        return 1
    fi
}

# Test help output
test_help() {
    log_test "Help output"
    if "$SCRIPT" --help | grep -q "GitHub Security Reporter"; then
        log_pass "Help output contains expected content"
    else
        log_fail "Help output missing or incorrect"
        return 1
    fi
}

# Test version output
test_version() {
    log_test "Version output"
    if "$SCRIPT" --version | grep -q "GitHub Security Reporter v"; then
        log_pass "Version output correct"
    else
        log_fail "Version output missing or incorrect"
        return 1
    fi
}

# Test missing arguments
test_missing_args() {
    log_test "Missing arguments handling"
    if ! "$SCRIPT" 2>/dev/null; then
        log_pass "Correctly handles missing arguments"
    else
        log_fail "Should fail with missing arguments"
        return 1
    fi
}

# Test dependency checks
test_dependencies() {
    log_test "Dependency checks"
    
    # Check for required tools
    local deps_ok=true
    
    if ! command -v gh &> /dev/null; then
        log_info "GitHub CLI (gh) not found - install from https://cli.github.com/"
        deps_ok=false
    fi
    
    if ! command -v jq &> /dev/null; then
        log_info "jq not found - install with: brew install jq (macOS) or apt-get install jq (Linux)"
        deps_ok=false
    fi
    
    if ! command -v curl &> /dev/null; then
        log_info "curl not found"
        deps_ok=false
    fi
    
    if $deps_ok; then
        log_pass "All required dependencies found"
    else
        log_fail "Some dependencies missing"
        return 1
    fi
}

# Test GitHub CLI authentication
test_gh_auth() {
    log_test "GitHub CLI authentication"
    if gh auth status --hostname github.com &> /dev/null; then
        log_pass "GitHub CLI authenticated"
    else
        log_info "GitHub CLI not authenticated - run 'gh auth login'"
        log_pass "Authentication check working (not authenticated)"
    fi
}

# Test script syntax
test_syntax() {
    log_test "Script syntax"
    if bash -n "$SCRIPT"; then
        log_pass "Script syntax is valid"
    else
        log_fail "Script has syntax errors"
        return 1
    fi
}

# Test with shellcheck if available
test_shellcheck() {
    log_test "ShellCheck linting"
    if command -v shellcheck &> /dev/null; then
        if shellcheck "$SCRIPT"; then
            log_pass "ShellCheck passed"
        else
            log_fail "ShellCheck found issues"
            return 1
        fi
    else
        log_info "ShellCheck not available - install for better testing"
        log_pass "Skipping ShellCheck (not installed)"
    fi
}

# Main test runner
main() {
    echo "🧪 Running GitHub Security Reporter Test Suite"
    echo "============================================="
    echo ""
    
    # Run all tests
    test_script_exists || true
    test_syntax || true
    test_help || true
    test_version || true
    test_missing_args || true
    test_dependencies || true
    test_gh_auth || true
    test_shellcheck || true
    
    echo ""
    echo "============================================="
    echo "Test Results: $TESTS_PASSED/$TESTS_RUN tests passed"
    
    if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

main "$@"