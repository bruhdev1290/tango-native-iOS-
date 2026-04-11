# Contributing

Thanks for your interest in contributing to Tranga! This document provides guidelines and instructions.

## Code of Conduct

Be respectful, inclusive, and professional in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch: `git checkout -b feature/your-feature`
4. Follow the development setup guide in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)

## Development Workflow

### Branch Naming
- Feature: `feature/short-description`
- Bug fix: `fix/short-description`
- Documentation: `docs/short-description`

### Commit Messages
- Use present tense: "Add feature" not "Added feature"
- Reference issues when applicable: "Fix #42: Improve error handling"
- Keep commits focused and atomic

### Code Style

Follow Swift best practices:

```swift
// ✅ Good
let viewModel = AuthViewModel(authService: authService)

// ❌ Avoid
let vm=AuthViewModel(as: authService)
```

**Guidelines:**
- Use meaningful variable names
- Keep functions focused and small
- Add documentation for public APIs
- Use `Sendable` for model types
- Implement services as `actor` types
- Use async/await throughout

### Testing

```bash
# Run all tests
swift test

# Run specific test
swift test --filter AuthServiceTests
```

Write tests for:
- New services or major features
- Bug fixes (include regression test)
- Error handling paths

**Test File Location:** `Tests/TaigaCoreTests/`

## Pull Request Process

1. Update documentation and examples
2. Ensure all tests pass: `swift test`
3. Create a descriptive PR title and description
4. Link related issues
5. Add a screenshot for UI changes
6. Wait for review and address feedback

## Reporting Issues

**Security Issues:** Email security concerns privately instead of opening a public issue.

**Bug Reports:** Include:
- iOS version and device/simulator
- Xcode version
- Steps to reproduce
- Expected vs. actual behavior
- Console errors or screenshots

**Feature Requests:** Describe:
- Use case and motivation
- Expected behavior
- Possible implementation approach

## Project Structure

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for an in-depth overview.

## Questions?

Feel free to open a discussion issue or contact the maintainers.

Happy coding! 🚀
