# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-21

### Added
- Initial release of GitHub Security Reporter
- Code scanning alerts collection and reporting
- Secret scanning detection and reporting
- Dependency vulnerability analysis
- SARIF file download and processing
- Interactive HTML dashboard generation
- Professional PDF report generation with multiple methods
- Comprehensive JSON data export
- Color-coded severity classification
- Responsive web design for all devices
- Multiple PDF generation fallbacks (wkhtmltopdf, Chrome, Node.js/Puppeteer)
- Automatic dependency installation (Puppeteer)
- Command-line help and version information
- Error handling and graceful degradation
- Support for GitHub.com repositories
- Cross-platform compatibility (macOS, Linux, Windows/WSL)

### Features
- **Multi-format Output**: HTML, PDF, JSON, and SARIF formats
- **Professional Styling**: Modern, GitHub-inspired design
- **Automatic Authentication**: Uses GitHub CLI credentials
- **Smart PDF Generation**: Multiple fallback methods for PDF creation
- **Real-time Data**: Pulls latest security scan results
- **Comprehensive Coverage**: Code scanning, secrets, dependencies
- **Executive Ready**: Professional reports for stakeholder review

### Technical Details
- Written in Bash for maximum compatibility
- Uses GitHub CLI for API access
- JSON processing with jq
- Responsive CSS design
- Headless browser PDF generation
- SARIF standard compliance
- RESTful API integration
- GraphQL queries for dependency data

### Documentation
- Comprehensive README with usage examples
- Installation instructions for multiple platforms
- Troubleshooting guide
- Contributing guidelines
- MIT license
- Code of conduct