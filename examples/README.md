# Examples

This directory contains example outputs and usage scenarios for the GitHub Security Reporter.

## Sample Reports

### Example 1: Clean Repository
- Repository: `username/clean-project`
- Status: No security issues found
- Files: [View Report](clean-project/summary.html)

### Example 2: Vulnerable Repository  
- Repository: `username/vulnerable-app`
- Status: Multiple security findings
- Files: [View Report](vulnerable-app/summary.html)

## Usage Examples

### Basic Usage
```bash
# Generate report for a public repository
./github-security-reporter.sh microsoft vscode

# Generate report for your own repository
./github-security-reporter.sh yourusername yourproject
```

### Advanced Usage
```bash
# Custom output directory
OUTPUT_DIR="/custom/path" ./github-security-reporter.sh owner repo

# Enable debug mode
DEBUG=1 ./github-security-reporter.sh owner repo
```

### CI/CD Integration
```yaml
# GitHub Actions workflow
name: Weekly Security Report
on:
  schedule:
    - cron: '0 9 * * MON'
jobs:
  security-report:
    runs-on: ubuntu-latest
    steps:
      - name: Generate Report
        run: |
          ./github-security-reporter.sh ${{ github.repository_owner }} ${{ github.event.repository.name }}
      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: security-report
          path: reports/
```

## Sample Output Structure

```
reports/
├── summary.html          # Interactive dashboard
├── summary.pdf           # Executive report
├── data.json            # Complete security data
└── latest.sarif         # SARIF analysis file
```

## Report Screenshots

### Dashboard Overview
![Dashboard](screenshots/dashboard.png)

### Alert Details
![Alert Details](screenshots/alert-details.png)

### PDF Report
![PDF Report](screenshots/pdf-report.png)