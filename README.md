# GitHub Security Reporter

A comprehensive tool that automatically generates professional security reports from GitHub's built-in security features.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-bash-green.svg)
![GitHub CLI](https://img.shields.io/badge/requires-GitHub%20CLI-blue.svg)

## Features

- 🔍 **Code Scanning Analysis** - Pull latest CodeQL and third-party security alerts
- 🔐 **Secret Detection** - Identify exposed API keys, tokens, and credentials
- 📊 **Dependency Vulnerabilities** - Check for known security issues in dependencies
- 📦 **Dependabot Alerts** - Review automated dependency security updates and alerts
- 📄 **Multiple Output Formats** - HTML dashboard, PDF report, JSON data, and SARIF files
- 🎨 **Professional Styling** - Clean, modern reports ready for stakeholder review
- 🚀 **Zero Configuration** - Works with existing GitHub security features
- 📱 **Responsive Design** - Reports look great on any device

## Quick Start

### Prerequisites

- [GitHub CLI](https://cli.github.com/) installed and authenticated
- `jq` for JSON processing
- Basic command line tools (`bash`, `curl`)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/github-security-reporter.git
cd github-security-reporter

# Make the script executable
chmod +x github-security-reporter.sh

# Authenticate with GitHub (if not already done)
gh auth login
```

### Usage

```bash
# Generate security report for any repository
./github-security-reporter.sh [owner] [repository]

# Examples
./github-security-reporter.sh microsoft vscode
./github-security-reporter.sh facebook react
./github-security-reporter.sh yourusername your-project
```

## Output Files

The tool generates a comprehensive security analysis in multiple formats:

### 📊 Interactive HTML Dashboard (`reports/summary.html`)
- Visual statistics with color-coded severity levels
- Detailed alert cards with file locations and descriptions
- Professional styling optimized for sharing with stakeholders
- Direct links to GitHub security tabs for investigation

### 📄 Professional PDF Report (`reports/summary.pdf`)
- Print-ready format perfect for executive summaries
- Multi-page layout with proper formatting
- Ideal for compliance documentation and meetings

### 📁 Raw Data Files
- `reports/data.json` - Complete security data for integration with other tools
- `reports/latest.sarif` - Industry-standard SARIF format for technical analysis

## Sample Output

```
Security Report Statistics:
├── Critical: 2 alerts
├── High: 15 alerts  
├── Medium: 43 alerts
├── Low: 8 alerts
└── Secrets: 12 findings

Generated Files:
├── reports/summary.html (Interactive Dashboard)
├── reports/summary.pdf (Executive Report)  
├── reports/data.json (Raw Data)
└── reports/latest.sarif (Technical Analysis)
```

## Report Features

### Security Overview Dashboard
- **Severity Breakdown** - Critical, High, Medium, Low vulnerability counts
- **Visual Statistics** - Color-coded cards for quick assessment
- **Trend Analysis** - Historical comparison capabilities

### Detailed Findings
- **File-Level Location** - Exact file paths and line numbers
- **Vulnerability Descriptions** - Clear explanations of security issues
- **Remediation Guidance** - Direct links to GitHub for detailed fixes
- **Rule Categories** - CWE mappings and security classifications

### Professional Presentation
- **Executive Summary** - High-level overview for stakeholders
- **Technical Details** - In-depth analysis for development teams
- **Compliance Ready** - Formatted for security audits and reviews

## Requirements

### System Requirements
- **Operating System**: macOS, Linux, or Windows (with WSL)
- **Shell**: Bash 4.0 or later
- **Memory**: Minimal (handles large repositories efficiently)

### Dependencies
- **GitHub CLI** (`gh`) - For API access and authentication
- **jq** - For JSON processing and data manipulation
- **curl** - For HTTP requests (usually pre-installed)

### Optional for PDF Generation
- **wkhtmltopdf** - Preferred PDF generator
- **Chrome/Chromium** - Headless browser for PDF generation
- **Node.js + Puppeteer** - Alternative PDF generation (auto-installs if needed)

## Installation Methods

### Method 1: Direct Download
```bash
curl -O https://raw.githubusercontent.com/yourusername/github-security-reporter/main/github-security-reporter.sh
chmod +x github-security-reporter.sh
```

### Method 2: Git Clone
```bash
git clone https://github.com/yourusername/github-security-reporter.git
cd github-security-reporter
chmod +x github-security-reporter.sh
```

### Method 3: Package Managers
```bash
# Homebrew (macOS/Linux)
brew install Moose0621/tap/github-security-reporter

# NPM (if you prefer)
npm install -g github-security-reporter
```

## Configuration

### GitHub Authentication
```bash
# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status
```

### PDF Generation Setup
```bash
# Option 1: Install wkhtmltopdf (recommended)
# macOS
brew install wkhtmltopdf

# Ubuntu/Debian
sudo apt-get install wkhtmltopdf

# Option 2: Use existing Chrome/Chromium (automatic detection)

# Option 3: Node.js + Puppeteer (auto-installs when needed)
npm install puppeteer
```

## Advanced Usage

### Custom Output Directory
```bash
# Specify custom output location
OUTPUT_DIR="/path/to/reports" ./github-security-reporter.sh owner repo
```

### Integration with CI/CD
```yaml
# GitHub Actions example
name: Security Report
on:
  schedule:
    - cron: '0 9 * * MON'  # Weekly on Monday at 9 AM
  
jobs:
  security-report:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup GitHub CLI
        run: |
          gh auth login --with-token <<< "${{ secrets.GITHUB_TOKEN }}"
      - name: Generate Security Report
        run: |
          curl -O https://raw.githubusercontent.com/yourusername/github-security-reporter/main/github-security-reporter.sh
          chmod +x github-security-reporter.sh
          ./github-security-reporter.sh ${{ github.repository_owner }} ${{ github.event.repository.name }}
      - name: Upload Reports
        uses: actions/upload-artifact@v4
        with:
          name: security-reports
          path: reports/
```

### Automated Scheduling
```bash
# Add to crontab for weekly reports
0 9 * * 1 cd /path/to/github-security-reporter && ./github-security-reporter.sh myorg myrepo
```

## Troubleshooting

### Common Issues

**GitHub CLI Not Authenticated**
```bash
Error: GitHub CLI is not authenticated
Solution: Run 'gh auth login' and follow the prompts
```

**Missing Dependencies**
```bash
Error: jq command not found
Solution: Install jq via your package manager
# macOS: brew install jq
# Ubuntu: sudo apt-get install jq
```

**Repository Not Found**
```bash
Error: Could not resolve to a Repository
Solution: Check repository name and verify access permissions
```

**PDF Generation Failed**
```bash
Warning: PDF generation tools not found
Solution: Install wkhtmltopdf, Chrome, or Node.js with Puppeteer
```

### Debug Mode
```bash
# Run with debug output
DEBUG=1 ./github-security-reporter.sh owner repo
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
```bash
git clone https://github.com/yourusername/github-security-reporter.git
cd github-security-reporter

# Run tests
./tests/run-tests.sh

# Lint the code
shellcheck github-security-reporter.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 **Documentation**: [Wiki](https://github.com/Moose0621/github-security-reporter/wiki)
- 🐛 **Issues**: [GitHub Issues](https://github.com/Moose0621/github-security-reporter/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/Moose0621/github-security-reporter/discussions)
- 📧 **Email**: security-reporter@yourdomain.com

## Acknowledgments

- GitHub for providing comprehensive security APIs
- The open-source community for tools like jq and GitHub CLI
- Contributors who have helped improve this tool

---

**Made with ❤️ for the security community**