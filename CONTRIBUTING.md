# Contributing to GitHub Security Reporter

Thank you for your interest in contributing to GitHub Security Reporter! We welcome contributions from the community.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear description** of the issue
- **Steps to reproduce** the behavior
- **Expected behavior**
- **Screenshots** if applicable
- **Environment details** (OS, shell version, GitHub CLI version)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear description** of the enhancement
- **Use case** explaining why this would be useful
- **Proposed implementation** if you have ideas

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Ensure all tests pass
6. Update documentation as needed
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/Moose0621/github-security-reporter.git
cd github-security-reporter

# Make the script executable
chmod +x github-security-reporter.sh

# Install development dependencies
npm install  # For testing tools

# Run linting
shellcheck github-security-reporter.sh

# Run tests
./tests/run-tests.sh
```

### Coding Standards

- Use bash best practices
- Follow existing code style
- Add comments for complex logic
- Use meaningful variable names
- Test your changes thoroughly

### Testing

- Test with different repository types
- Verify all output formats work correctly
- Check error handling scenarios
- Test on different operating systems if possible

## Development Guidelines

### Shell Script Best Practices

- Use `set -e` for error handling
- Quote variables properly
- Use `local` for function variables
- Check command availability before using
- Provide meaningful error messages

### Documentation

- Update README.md for new features
- Add inline comments for complex code
- Update help text if adding new options
- Include examples in documentation

## Release Process

1. Update version in script
2. Update CHANGELOG.md
3. Create release notes
4. Tag the release
5. Update documentation

## Questions?

Feel free to open an issue for any questions about contributing.