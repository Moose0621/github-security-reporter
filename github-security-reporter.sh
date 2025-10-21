#!/bin/bash

# GitHub Security Reporter
# Generates comprehensive security reports from GitHub's built-in security features
# 
# Usage: 
#   Single repository: ./github-security-reporter.sh <owner> <repo_name>
#   Multiple repositories: ./github-security-reporter.sh --list <owner/repo1> <owner/repo2> ...
#   From file: ./github-security-reporter.sh --file <repos.txt>
# Examples:
#   ./github-security-reporter.sh microsoft vscode
#   ./github-security-reporter.sh --list microsoft/vscode facebook/react google/go
#   ./github-security-reporter.sh --file my-repos.txt
#
# Requirements:
# - GitHub CLI (gh) installed and authenticated
# - jq for JSON processing
# - Basic command line tools (bash, curl)
#
# GitHub: https://github.com/Moose0621/github-security-reporter
# License: MIT

set -e

# Script metadata
SCRIPT_VERSION="1.1.0"
SCRIPT_NAME="GitHub Security Reporter"

# Global configuration
BASE_OUTPUT_DIR="${OUTPUT_DIR:-./reports}"
TEMPLATE="summary.html"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Help function
show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

USAGE:
    Single repository:
    $0 <owner> <repo_name>

    Multiple repositories:
    $0 --list <owner/repo1> <owner/repo2> [owner/repo3] ...
    $0 --file <repos.txt>

EXAMPLES:
    Single repository:
    $0 microsoft vscode
    $0 facebook react

    Multiple repositories:
    $0 --list microsoft/vscode facebook/react google/go
    $0 --file my-repos.txt

    Repository list file format (one per line):
    microsoft/vscode
    facebook/react
    google/go

DESCRIPTION:
    Generates comprehensive security reports from GitHub's security features:
    - Code scanning alerts (CodeQL, third-party tools)
    - Secret scanning (exposed credentials)
    - Dependency vulnerabilities
    - SARIF analysis files

OUTPUT:
    For single repository:
    reports/<owner>-<repo>/summary.html    - Interactive HTML dashboard
    reports/<owner>-<repo>/summary.pdf     - Professional PDF report
    reports/<owner>-<repo>/data.json       - Complete security data
    reports/<owner>-<repo>/latest.sarif    - Industry-standard SARIF format

    For multiple repositories:
    reports/<owner1>-<repo1>/...
    reports/<owner2>-<repo2>/...
    reports/summary-report.html            - Combined overview report

REQUIREMENTS:
    - GitHub CLI (gh) installed and authenticated
    - jq for JSON processing
    - Optional: wkhtmltopdf, Chrome, or Node.js for PDF generation

AUTHENTICATION:
    Run 'gh auth login' to authenticate with GitHub before using this tool.

For more information, visit:
https://github.com/Moose0621/github-security-reporter
EOF
}

# Version function
show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
}

# Parse command line arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--version" ]] || [[ "$1" == "-v" ]]; then
    show_version
    exit 0
fi

# Initialize variables
REPOSITORIES=()
MODE="single"

# Parse arguments
if [[ "$1" == "--list" ]]; then
    MODE="list"
    shift
    # Convert owner/repo format to array
    for repo in "$@"; do
        if [[ "$repo" =~ ^([^/]+)/(.+)$ ]]; then
            REPOSITORIES+=("${BASH_REMATCH[1]} ${BASH_REMATCH[2]}")
        else
            log_error "Invalid repository format: $repo. Use owner/repo format."
            exit 1
        fi
    done
elif [[ "$1" == "--file" ]]; then
    MODE="file"
    REPO_FILE="$2"
    if [[ ! -f "$REPO_FILE" ]]; then
        log_error "Repository file not found: $REPO_FILE"
        exit 1
    fi
    # Read repositories from file
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        if [[ "$line" =~ ^([^/]+)/(.+)$ ]]; then
            REPOSITORIES+=("${BASH_REMATCH[1]} ${BASH_REMATCH[2]}")
        else
            log_error "Invalid repository format in file: $line. Use owner/repo format."
            exit 1
        fi
    done < "$REPO_FILE"
else
    # Single repository mode
    OWNER="$1"
    REPO_NAME="$2"
    if [ -z "$OWNER" ] || [ -z "$REPO_NAME" ]; then
        log_error "Missing required arguments"
        echo ""
        echo "Usage: $0 <owner> <repo_name>"
        echo "   or: $0 --list <owner/repo1> <owner/repo2> ..."
        echo "   or: $0 --file <repos.txt>"
        echo "Example: $0 microsoft vscode"
        echo ""
        echo "For more help, run: $0 --help"
        exit 1
    fi
    REPOSITORIES=("$OWNER $REPO_NAME")
fi

if [[ ${#REPOSITORIES[@]} -eq 0 ]]; then
    log_error "No repositories specified"
    exit 1
fi

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    log_error "jq is not installed"
    echo "Install jq for JSON processing:"
    echo "  macOS: brew install jq"
    echo "  Ubuntu: sudo apt-get install jq"
    echo "  Other: https://stedolan.github.io/jq/download/"
    exit 1
fi

# Always use github.com for this script
HOSTNAME="github.com"
GH_HOST_FLAG="--hostname github.com"

# Check authentication for GitHub.com
if ! gh auth status $GH_HOST_FLAG &> /dev/null; then
    log_error "GitHub CLI is not authenticated for $HOSTNAME"
    echo "Run 'gh auth login $GH_HOST_FLAG' to authenticate with $HOSTNAME"
    exit 1
fi

log_success "Authentication verified"

# Function to process a single repository
process_repository() {
    local OWNER="$1"
    local REPO_NAME="$2"
    local REPO="$OWNER/$REPO_NAME"
    
    # Create repository-specific output directory
    local OUTPUT_DIR="$BASE_OUTPUT_DIR/${OWNER}-${REPO_NAME}"
    mkdir -p "$OUTPUT_DIR"
    
    log_info "Starting security analysis for $REPO"

    # Step 1: Fetch latest SARIF results from GitHub code scanning
    log_info "Fetching latest SARIF results from GitHub code scanning..."

    # Get all code scanning alerts and extract SARIF data
    log_info "Fetching code scanning alerts..."
    if ! CODE_SCANNING_ALERTS=$(gh api repos/$REPO/code-scanning/alerts $GH_HOST_FLAG 2>&1); then
        log_warning "Could not fetch code scanning alerts: $CODE_SCANNING_ALERTS"
        CODE_SCANNING_ALERTS="[]"
    fi

    # Get the latest code scanning analyses to fetch SARIF files
    log_info "Fetching code scanning analyses..."
    if ! ANALYSES=$(gh api repos/$REPO/code-scanning/analyses $GH_HOST_FLAG 2>&1); then
        log_warning "Could not fetch code scanning analyses: $ANALYSES"
        ANALYSES="[]"
    fi

    # Download the latest SARIF file from the most recent analysis
    LATEST_ANALYSIS_ID=$(echo "$ANALYSES" | jq -r '.[0].id // empty' 2>/dev/null)

    if [ -n "$LATEST_ANALYSIS_ID" ] && [ "$LATEST_ANALYSIS_ID" != "null" ]; then
        log_info "Downloading SARIF file from analysis ID: $LATEST_ANALYSIS_ID"
        if SARIF_DATA=$(gh api repos/$REPO/code-scanning/analyses/$LATEST_ANALYSIS_ID --header "Accept: application/sarif+json" $GH_HOST_FLAG 2>&1); then
            echo "$SARIF_DATA" > "$OUTPUT_DIR/latest.sarif"
            # Convert SARIF to JSON array format expected by the report
            SARIF_JSON="[$SARIF_DATA]"
            log_success "SARIF data downloaded successfully"
        else
            log_warning "Could not download SARIF data: $SARIF_DATA"
            SARIF_JSON="[]"
        fi
    else
        log_info "No code scanning analyses found. Using empty SARIF data."
        SARIF_JSON="[]"
    fi

    # Step 2: Fetch additional security data from GitHub using GitHub CLI
    log_info "Fetching code scanning alerts..."
    if ! CODE_SCANNING_ALERTS=$(gh api repos/$REPO/code-scanning/alerts $GH_HOST_FLAG 2>&1); then
        log_warning "Could not fetch code scanning alerts: $CODE_SCANNING_ALERTS"
        CODE_SCANNING_ALERTS="[]"
    fi

    log_info "Fetching dependency and vulnerability data using GitHub CLI..."
    if ! DEPENDENCY_JSON=$(gh api graphql $GH_HOST_FLAG -f query='
      query($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          dependencyGraphManifests(first: 100) {
            edges {
              node {
                filename
                dependencies(first: 100) {
                  nodes {
                    packageName
                    packageManager
                    requirements
                  }
                }
              }
            }
          }
          vulnerabilityAlerts(first: 100) {
            nodes {
              vulnerableManifestFilename
              securityVulnerability {
                package {
                  name
                  ecosystem
                }
                severity
              }
            }
          }
        }
      }
    ' -F owner="$OWNER" -F name="$REPO_NAME" 2>&1); then
        log_warning "Could not fetch dependency data: $DEPENDENCY_JSON"
        DEPENDENCY_JSON='{"data":{"repository":{"dependencyGraphManifests":{"edges":[]},"vulnerabilityAlerts":{"nodes":[]}}}}'
    fi

    # Fetch secret scanning alerts if available
    log_info "Fetching secret scanning alerts..."
    if ! SECRET_SCANNING_ALERTS=$(gh api repos/$REPO/secret-scanning/alerts $GH_HOST_FLAG 2>/dev/null); then
        log_info "Secret scanning alerts not available or accessible"
        SECRET_SCANNING_ALERTS="[]"
    fi

    # Step 3: Combine all data into a comprehensive data.json
    log_info "Combining report data..."

    # Write SARIF data to temporary file to avoid argument list too long
    echo "$SARIF_JSON" > "$OUTPUT_DIR/temp_sarif.json"

    jq -n \
      --slurpfile sarif "$OUTPUT_DIR/temp_sarif.json" \
      --argjson codeScanning "$CODE_SCANNING_ALERTS" \
      --argjson dependency "$DEPENDENCY_JSON" \
      --argjson secretScanning "$SECRET_SCANNING_ALERTS" \
      --arg repo "$REPO" \
      --arg owner "$OWNER" \
      --arg repoName "$REPO_NAME" \
      --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg version "$SCRIPT_VERSION" \
      '{
        metadata: {
          repository: $repo,
          owner: $owner, 
          repositoryName: $repoName,
          generatedAt: $timestamp,
          toolVersion: $version
        },
        sarifReports: $sarif, 
        codeScanning: $codeScanning, 
        dependencies: $dependency,
        secretScanning: $secretScanning
      }' > "$OUTPUT_DIR/data.json"

    # Clean up temporary file
    rm "$OUTPUT_DIR/temp_sarif.json"

    log_success "Data collection completed"

    # Generate HTML and PDF reports
    generate_reports "$OWNER" "$REPO_NAME" "$OUTPUT_DIR"
    
    # Return statistics for summary
    local CRITICAL_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq '[.[] | select(.rule.security_severity_level == "critical")] | length')
    local HIGH_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq '[.[] | select(.rule.security_severity_level == "high")] | length')
    local MEDIUM_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq '[.[] | select(.rule.security_severity_level == "medium")] | length')
    local LOW_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq '[.[] | select(.rule.security_severity_level == "low")] | length')
    local SECRET_COUNT=$(echo "$SECRET_SCANNING_ALERTS" | jq 'length')
    
    echo "$REPO $CRITICAL_COUNT $HIGH_COUNT $MEDIUM_COUNT $LOW_COUNT $SECRET_COUNT"
}

# Function to generate HTML and PDF reports
generate_reports() {
    local OWNER="$1"
    local REPO_NAME="$2"
    local OUTPUT_DIR="$3"
    local REPO="$OWNER/$REPO_NAME"
    
    # Read the data
    local CODE_SCANNING_ALERTS=$(jq -r '.codeScanning' "$OUTPUT_DIR/data.json")
    local SECRET_SCANNING_ALERTS=$(jq -r '.secretScanning' "$OUTPUT_DIR/data.json")
    
    # Extract summary statistics
    local CODE_SCANNING_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq 'length')
    local SECRET_SCANNING_COUNT=$(echo "$SECRET_SCANNING_ALERTS" | jq 'length')
    
    # Count by severity
    local HIGH_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq '[.[] | select(.rule.security_severity_level == "high")] | length')
    local MEDIUM_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq '[.[] | select(.rule.security_severity_level == "medium")] | length')
    local LOW_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq '[.[] | select(.rule.security_severity_level == "low")] | length')
    local CRITICAL_COUNT=$(echo "$CODE_SCANNING_ALERTS" | jq '[.[] | select(.rule.security_severity_level == "critical")] | length')

    log_info "Generating comprehensive HTML report..."
    
    # Generate HTML with actual data
    cat > "$OUTPUT_DIR/summary.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Report - $REPO</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            background: #f8f9fa; 
            color: #333; 
            line-height: 1.6;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; 
            padding: 30px; 
            border-radius: 10px; 
            margin-bottom: 30px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header .repo { font-size: 1.2em; opacity: 0.9; }
        .stats-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 20px; 
            margin-bottom: 30px; 
        }
        .stat-card { 
            background: white; 
            padding: 25px; 
            border-radius: 10px; 
            text-align: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            border-left: 4px solid #ddd;
        }
        .stat-card.critical { border-left-color: #dc3545; }
        .stat-card.high { border-left-color: #fd7e14; }
        .stat-card.medium { border-left-color: #ffc107; }
        .stat-card.low { border-left-color: #6f42c1; }
        .stat-card.info { border-left-color: #17a2b8; }
        .stat-number { font-size: 2.5em; font-weight: bold; margin-bottom: 5px; }
        .stat-label { color: #666; font-size: 0.9em; text-transform: uppercase; letter-spacing: 1px; }
        .section { 
            background: white; 
            margin-bottom: 30px; 
            border-radius: 10px; 
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }
        .section-header { 
            background: #495057; 
            color: white; 
            padding: 20px; 
            font-size: 1.3em; 
            font-weight: 600;
        }
        .section-content { padding: 20px; }
        .alert-item { 
            padding: 15px; 
            margin: 10px 0; 
            border-radius: 8px; 
            border-left: 4px solid #ddd;
            background: #f8f9fa;
        }
        .alert-item.critical { border-left-color: #dc3545; background: #f8d7da; }
        .alert-item.high { border-left-color: #fd7e14; background: #ffeaa7; }
        .alert-item.medium { border-left-color: #ffc107; background: #fff3cd; }
        .alert-item.low { border-left-color: #6f42c1; background: #e2e3f3; }
        .alert-title { font-weight: 600; margin-bottom: 8px; color: #333; }
        .alert-description { color: #666; margin-bottom: 8px; }
        .alert-location { 
            font-family: 'Monaco', 'Menlo', monospace; 
            font-size: 0.85em; 
            color: #495057;
            background: #e9ecef;
            padding: 5px 8px;
            border-radius: 4px;
            display: inline-block;
        }
        .severity-badge { 
            display: inline-block; 
            padding: 4px 8px; 
            border-radius: 12px; 
            font-size: 0.75em; 
            font-weight: 600; 
            text-transform: uppercase;
            margin-left: 10px;
        }
        .severity-critical { background: #dc3545; color: white; }
        .severity-high { background: #fd7e14; color: white; }
        .severity-medium { background: #ffc107; color: black; }
        .severity-low { background: #6f42c1; color: white; }
        .no-data { text-align: center; color: #666; padding: 40px; }
        .timestamp { text-align: right; color: #666; margin-top: 30px; font-size: 0.9em; }
        .rule-tags { margin-top: 8px; }
        .tag { 
            display: inline-block; 
            background: #e9ecef; 
            color: #495057; 
            padding: 2px 6px; 
            border-radius: 3px; 
            font-size: 0.7em; 
            margin-right: 5px;
        }
        .footer { 
            text-align: center; 
            color: #666; 
            padding: 20px; 
            border-top: 1px solid #dee2e6; 
            margin-top: 30px; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 Security Report</h1>
            <div class="repo">Repository: <strong>$REPO</strong></div>
            <div class="repo">Generated: <strong>$(date)</strong></div>
            <div class="repo">Tool Version: <strong>$SCRIPT_VERSION</strong></div>
        </div>

        <div class="stats-grid">
            <div class="stat-card critical">
                <div class="stat-number">$CRITICAL_COUNT</div>
                <div class="stat-label">Critical</div>
            </div>
            <div class="stat-card high">
                <div class="stat-number">$HIGH_COUNT</div>
                <div class="stat-label">High</div>
            </div>
            <div class="stat-card medium">
                <div class="stat-number">$MEDIUM_COUNT</div>
                <div class="stat-label">Medium</div>
            </div>
            <div class="stat-card low">
                <div class="stat-number">$LOW_COUNT</div>
                <div class="stat-label">Low</div>
            </div>
            <div class="stat-card info">
                <div class="stat-number">$SECRET_SCANNING_COUNT</div>
                <div class="stat-label">Secrets Found</div>
            </div>
        </div>

        <div class="section">
            <div class="section-header">📊 Code Scanning Alerts ($CODE_SCANNING_COUNT total)</div>
            <div class="section-content">
EOF

    # Add code scanning alerts to HTML
    if [ "$CODE_SCANNING_COUNT" -gt 0 ]; then
        echo "$CODE_SCANNING_ALERTS" | jq -r '.[] | @json' | while IFS= read -r alert; do
            ALERT_NUMBER=$(echo "$alert" | jq -r '.number')
            ALERT_RULE=$(echo "$alert" | jq -r '.rule.description')
            ALERT_SEVERITY=$(echo "$alert" | jq -r '.rule.security_severity_level // "unknown"')
            ALERT_PATH=$(echo "$alert" | jq -r '.most_recent_instance.location.path')
            ALERT_LINE=$(echo "$alert" | jq -r '.most_recent_instance.location.start_line')
            ALERT_TAGS=$(echo "$alert" | jq -r '.rule.tags[]?' | head -3 | tr '\n' ' ')
            
            cat >> "$OUTPUT_DIR/summary.html" << EOF
                <div class="alert-item $ALERT_SEVERITY">
                    <div class="alert-title">
                        $ALERT_RULE
                        <span class="severity-badge severity-$ALERT_SEVERITY">$ALERT_SEVERITY</span>
                    </div>
                    <div class="alert-location">$ALERT_PATH:$ALERT_LINE</div>
                    <div class="rule-tags">
EOF
            if [ -n "$ALERT_TAGS" ]; then
                echo "$ALERT_TAGS" | tr ' ' '\n' | while read -r tag; do
                    if [ -n "$tag" ]; then
                        echo "                        <span class=\"tag\">$tag</span>" >> "$OUTPUT_DIR/summary.html"
                    fi
                done
            fi
            cat >> "$OUTPUT_DIR/summary.html" << EOF
                    </div>
                </div>
EOF
        done
    else
        echo '                <div class="no-data">✅ No code scanning alerts found</div>' >> "$OUTPUT_DIR/summary.html"
    fi

    cat >> "$OUTPUT_DIR/summary.html" << EOF
            </div>
        </div>

        <div class="section">
            <div class="section-header">🔐 Secret Scanning Alerts ($SECRET_SCANNING_COUNT total)</div>
            <div class="section-content">
EOF

    # Add secret scanning alerts to HTML
    if [ "$SECRET_SCANNING_COUNT" -gt 0 ]; then
        echo "$SECRET_SCANNING_ALERTS" | jq -r '.[] | @json' | while IFS= read -r secret; do
            SECRET_TYPE=$(echo "$secret" | jq -r '.secret_type_display_name // .secret_type')
            SECRET_PATH=$(echo "$secret" | jq -r '.locations[0].details.path // "Unknown"')
            SECRET_STATE=$(echo "$secret" | jq -r '.state')
            
            cat >> "$OUTPUT_DIR/summary.html" << EOF
                <div class="alert-item high">
                    <div class="alert-title">
                        $SECRET_TYPE detected
                        <span class="severity-badge severity-high">$SECRET_STATE</span>
                    </div>
                    <div class="alert-location">$SECRET_PATH</div>
                </div>
EOF
        done
    else
        echo '                <div class="no-data">✅ No secrets detected</div>' >> "$OUTPUT_DIR/summary.html"
    fi

    cat >> "$OUTPUT_DIR/summary.html" << EOF
            </div>
        </div>

        <div class="footer">
            <p>Report generated on $(date) | 
            <a href="https://github.com/$REPO/security" target="_blank">View on GitHub</a> | 
            Generated by <a href="https://github.com/Moose0621/github-security-reporter" target="_blank">GitHub Security Reporter v$SCRIPT_VERSION</a></p>
        </div>
    </div>
</body>
</html>
EOF

    log_success "HTML report generated"

    # Generate PDF
    generate_pdf "$OUTPUT_DIR"
    
    log_success "Security report generated successfully!"
    echo ""
    echo "📊 Report Statistics:"
    echo "   Critical: $CRITICAL_COUNT alerts"
    echo "   High: $HIGH_COUNT alerts"
    echo "   Medium: $MEDIUM_COUNT alerts" 
    echo "   Low: $LOW_COUNT alerts"
    echo "   Secrets: $SECRET_SCANNING_COUNT findings"
    echo ""
    echo "📁 Generated Files:"
    echo "   HTML Report: $OUTPUT_DIR/summary.html"
    echo "   Data file: $OUTPUT_DIR/data.json"
    if [ -f "$OUTPUT_DIR/latest.sarif" ]; then
        echo "   SARIF file: $OUTPUT_DIR/latest.sarif"
    fi
    if [ -f "$OUTPUT_DIR/summary.pdf" ]; then
        echo "   PDF Report: $OUTPUT_DIR/summary.pdf"
    fi
    echo ""
}

# Function to generate PDF with multiple fallback methods
generate_pdf() {
    local OUTPUT_DIR="$1"
    
    log_info "Generating PDF report..."

    # Method 1: Try wkhtmltopdf if available
    if command -v wkhtmltopdf &> /dev/null; then
        log_info "Using wkhtmltopdf for PDF generation..."
        wkhtmltopdf --page-size A4 --margin-top 0.75in --margin-right 0.75in --margin-bottom 0.75in --margin-left 0.75in \
            --disable-smart-shrinking --print-media-type "$OUTPUT_DIR/summary.html" "$OUTPUT_DIR/summary.pdf"
        log_success "PDF generated with wkhtmltopdf"

    # Method 2: Try Chrome/Chromium headless
    elif command -v google-chrome &> /dev/null; then
        log_info "Using Google Chrome for PDF generation..."
        google-chrome --headless --disable-gpu --no-sandbox --print-to-pdf="$OUTPUT_DIR/summary.pdf" \
            --virtual-time-budget=5000 "file://$(pwd)/$OUTPUT_DIR/summary.html"
        log_success "PDF generated with Chrome"

    elif command -v chromium &> /dev/null; then
        log_info "Using Chromium for PDF generation..."
        chromium --headless --disable-gpu --no-sandbox --print-to-pdf="$OUTPUT_DIR/summary.pdf" \
            --virtual-time-budget=5000 "file://$(pwd)/$OUTPUT_DIR/summary.html"
        log_success "PDF generated with Chromium"

    elif command -v chromium-browser &> /dev/null; then
        log_info "Using Chromium browser for PDF generation..."
        chromium-browser --headless --disable-gpu --no-sandbox --print-to-pdf="$OUTPUT_DIR/summary.pdf" \
            --virtual-time-budget=5000 "file://$(pwd)/$OUTPUT_DIR/summary.html"
        log_success "PDF generated with Chromium browser"

    # Method 3: Create Node.js PDF generator if Node.js is available
    elif command -v node &> /dev/null; then
        log_info "Setting up Node.js PDF generation..."
        
        # Check if puppeteer is installed, if not try to install it
        if ! node -e "require('puppeteer')" 2>/dev/null; then
            log_info "Installing puppeteer for PDF generation..."
            npm install puppeteer 2>/dev/null || {
                log_warning "Could not install puppeteer automatically"
                log_info "To enable PDF generation, run: npm install puppeteer"
            }
        fi
        
        # Create PDF generator script
        cat > html2pdf.js << 'EOF'
const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
  try {
    const htmlFile = process.argv[2];
    const pdfFile = process.argv[3];
    
    if (!htmlFile || !pdfFile) {
      console.error('Usage: node html2pdf.js <input.html> <output.pdf>');
      process.exit(1);
    }
    
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    const htmlContent = fs.readFileSync(htmlFile, 'utf-8');
    await page.setContent(htmlContent, { waitUntil: 'networkidle0' });
    
    await page.pdf({
      path: pdfFile,
      format: 'A4',
      margin: {
        top: '20mm',
        right: '20mm',
        bottom: '20mm',
        left: '20mm'
      },
      printBackground: true
    });
    
    await browser.close();
    console.log(`PDF generated successfully: ${pdfFile}`);
  } catch (error) {
    console.error('Error generating PDF:', error.message);
    process.exit(1);
  }
})();
EOF

        # Try to generate PDF with Node.js
        if node html2pdf.js "$OUTPUT_DIR/summary.html" "$OUTPUT_DIR/summary.pdf" 2>/dev/null; then
            log_success "PDF generated with Node.js/Puppeteer"
            rm html2pdf.js
        else
            log_warning "PDF generation with Node.js failed"
            rm html2pdf.js 2>/dev/null
        fi

    # Method 4: Fallback - create a simple text-based PDF instruction
    else
        log_info "Creating PDF generation instructions..."
        cat > "$OUTPUT_DIR/generate_pdf.md" << EOF
# PDF Generation Instructions

To generate a PDF from the HTML report, you can use one of these methods:

## Option 1: Install wkhtmltopdf
\`\`\`bash
# On macOS:
brew install wkhtmltopdf

# On Ubuntu/Debian:
sudo apt-get install wkhtmltopdf

# Then run:
wkhtmltopdf summary.html summary.pdf
\`\`\`

## Option 2: Use Chrome/Chromium
\`\`\`bash
# Using Google Chrome:
google-chrome --headless --disable-gpu --print-to-pdf=summary.pdf file://\$(pwd)/summary.html

# Using Chromium:
chromium --headless --disable-gpu --print-to-pdf=summary.pdf file://\$(pwd)/summary.html
\`\`\`

## Option 3: Use Node.js with Puppeteer
\`\`\`bash
npm install puppeteer
# Then use the html2pdf.js script provided
\`\`\`

## Option 4: Print from Browser
1. Open summary.html in your web browser
2. Press Ctrl+P (or Cmd+P on Mac)
3. Select "Save as PDF" as the destination
4. Adjust settings as needed and save
EOF

        log_info "PDF generation tools not found. See generate_pdf.md for instructions."
    fi
}

# Function to generate a summary report for multiple repositories
generate_summary_report() {
    local REPO_STATS=("$@")
    local SUMMARY_DIR="$BASE_OUTPUT_DIR"
    
    log_info "Generating summary report for multiple repositories..."
    
    # Calculate totals
    local TOTAL_REPOS=${#REPO_STATS[@]}
    local TOTAL_CRITICAL=0
    local TOTAL_HIGH=0
    local TOTAL_MEDIUM=0
    local TOTAL_LOW=0
    local TOTAL_SECRETS=0
    
    for stat in "${REPO_STATS[@]}"; do
        read -r repo critical high medium low secrets <<< "$stat"
        TOTAL_CRITICAL=$((TOTAL_CRITICAL + critical))
        TOTAL_HIGH=$((TOTAL_HIGH + high))
        TOTAL_MEDIUM=$((TOTAL_MEDIUM + medium))
        TOTAL_LOW=$((TOTAL_LOW + low))
        TOTAL_SECRETS=$((TOTAL_SECRETS + secrets))
    done
    
    # Generate summary HTML report
    cat > "$SUMMARY_DIR/summary-report.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Multi-Repository Security Summary</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            background: #f8f9fa; 
            color: #333; 
            line-height: 1.6;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; 
            padding: 30px; 
            border-radius: 10px; 
            margin-bottom: 30px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header .info { font-size: 1.2em; opacity: 0.9; }
        .stats-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 20px; 
            margin-bottom: 30px; 
        }
        .stat-card { 
            background: white; 
            padding: 25px; 
            border-radius: 10px; 
            text-align: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            border-left: 4px solid #ddd;
        }
        .stat-card.critical { border-left-color: #dc3545; }
        .stat-card.high { border-left-color: #fd7e14; }
        .stat-card.medium { border-left-color: #ffc107; }
        .stat-card.low { border-left-color: #6f42c1; }
        .stat-card.info { border-left-color: #17a2b8; }
        .stat-number { font-size: 2.5em; font-weight: bold; margin-bottom: 5px; }
        .stat-label { color: #666; font-size: 0.9em; text-transform: uppercase; letter-spacing: 1px; }
        .repos-table { 
            background: white; 
            border-radius: 10px; 
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }
        .table-header { 
            background: #495057; 
            color: white; 
            padding: 20px; 
            font-size: 1.3em; 
            font-weight: 600;
        }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 15px; text-align: left; border-bottom: 1px solid #dee2e6; }
        th { background: #f8f9fa; font-weight: 600; }
        .severity-critical { color: #dc3545; font-weight: bold; }
        .severity-high { color: #fd7e14; font-weight: bold; }
        .severity-medium { color: #ffc107; font-weight: bold; }
        .severity-low { color: #6f42c1; font-weight: bold; }
        .repo-link { color: #007bff; text-decoration: none; }
        .repo-link:hover { text-decoration: underline; }
        .footer { 
            text-align: center; 
            color: #666; 
            padding: 20px; 
            border-top: 1px solid #dee2e6; 
            margin-top: 30px; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 Multi-Repository Security Summary</h1>
            <div class="info">Analyzed $TOTAL_REPOS repositories</div>
            <div class="info">Generated: $(date)</div>
            <div class="info">Tool Version: $SCRIPT_VERSION</div>
        </div>

        <div class="stats-grid">
            <div class="stat-card info">
                <div class="stat-number">$TOTAL_REPOS</div>
                <div class="stat-label">Repositories</div>
            </div>
            <div class="stat-card critical">
                <div class="stat-number">$TOTAL_CRITICAL</div>
                <div class="stat-label">Critical</div>
            </div>
            <div class="stat-card high">
                <div class="stat-number">$TOTAL_HIGH</div>
                <div class="stat-label">High</div>
            </div>
            <div class="stat-card medium">
                <div class="stat-number">$TOTAL_MEDIUM</div>
                <div class="stat-label">Medium</div>
            </div>
            <div class="stat-card low">
                <div class="stat-number">$TOTAL_LOW</div>
                <div class="stat-label">Low</div>
            </div>
            <div class="stat-card info">
                <div class="stat-number">$TOTAL_SECRETS</div>
                <div class="stat-label">Secrets</div>
            </div>
        </div>

        <div class="repos-table">
            <div class="table-header">📊 Repository Details</div>
            <table>
                <thead>
                    <tr>
                        <th>Repository</th>
                        <th>Critical</th>
                        <th>High</th>
                        <th>Medium</th>
                        <th>Low</th>
                        <th>Secrets</th>
                        <th>Report</th>
                    </tr>
                </thead>
                <tbody>
EOF

    # Add repository rows
    for stat in "${REPO_STATS[@]}"; do
        read -r repo critical high medium low secrets <<< "$stat"
        owner_repo=$(echo "$repo" | tr '/' '-')
        
        cat >> "$SUMMARY_DIR/summary-report.html" << EOF
                    <tr>
                        <td><a href="https://github.com/$repo" class="repo-link" target="_blank">$repo</a></td>
                        <td class="severity-critical">$critical</td>
                        <td class="severity-high">$high</td>
                        <td class="severity-medium">$medium</td>
                        <td class="severity-low">$low</td>
                        <td>$secrets</td>
                        <td><a href="./$owner_repo/summary.html" class="repo-link">View Report</a></td>
                    </tr>
EOF
    done

    cat >> "$SUMMARY_DIR/summary-report.html" << EOF
                </tbody>
            </table>
        </div>

        <div class="footer">
            <p>Report generated on $(date) | 
            Generated by <a href="https://github.com/Moose0621/github-security-reporter" target="_blank">GitHub Security Reporter v$SCRIPT_VERSION</a></p>
        </div>
    </div>
</body>
</html>
EOF

    log_success "Summary report generated: $SUMMARY_DIR/summary-report.html"
}

# Main execution
echo "Starting GitHub Security Reporter v$SCRIPT_VERSION..."
echo "Mode: $MODE"
echo "Repositories to process: ${#REPOSITORIES[@]}"
echo ""

# Create base output directory
mkdir -p "$BASE_OUTPUT_DIR"

# Process repositories
REPO_STATS=()
FAILED_REPOS=()

for repo_info in "${REPOSITORIES[@]}"; do
    read -r owner repo_name <<< "$repo_info"
    
    echo ""
    log_info "Processing repository: $owner/$repo_name"
    
    # Process the repository and capture the result
    if result=$(process_repository "$owner" "$repo_name" 2>&1); then
        # Extract the statistics from the result
        stat_line=$(echo "$result" | tail -n 1)
        REPO_STATS+=("$stat_line")
        log_success "Completed: $owner/$repo_name"
    else
        log_error "Failed to process: $owner/$repo_name"
        FAILED_REPOS+=("$owner/$repo_name")
    fi
done

# Generate summary report if multiple repositories were processed
if [[ ${#REPOSITORIES[@]} -gt 1 ]]; then
    echo ""
    generate_summary_report "${REPO_STATS[@]}"
fi

# Final summary
echo ""
echo "================================================"
log_success "GitHub Security Reporter completed!"
echo ""
echo "📊 Summary:"
echo "   Total repositories: ${#REPOSITORIES[@]}"
echo "   Successfully processed: ${#REPO_STATS[@]}"
echo "   Failed: ${#FAILED_REPOS[@]}"

if [[ ${#FAILED_REPOS[@]} -gt 0 ]]; then
    echo ""
    echo "❌ Failed repositories:"
    for failed_repo in "${FAILED_REPOS[@]}"; do
        echo "   - $failed_repo"
    done
fi

echo ""
echo "📁 Output directory: $BASE_OUTPUT_DIR"
if [[ ${#REPOSITORIES[@]} -gt 1 ]]; then
    echo "📄 Summary report: $BASE_OUTPUT_DIR/summary-report.html"
fi

echo ""
log_info "Reports are ready for review!"