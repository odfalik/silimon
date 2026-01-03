# Contributing to Silimon

Thanks for your interest in contributing to Silimon! This document outlines how to get started.

## Development Setup

### Prerequisites

- macOS 13.0 (Ventura) or later
- Apple Silicon Mac (M1, M2, M3, etc.)
- Xcode 14.0+ with Command Line Tools
- Swift 5.9+

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/odfalik/silimon.git
   cd silimon
   ```

2. **Build the project**
   ```bash
   make build
   ```

3. **Set up passwordless powermetrics** (required for full functionality)
   ```bash
   sudo Scripts/setup-sudo.sh
   ```

4. **Run in development mode**
   ```bash
   make dev
   ```

### Available Make Commands

| Command | Description |
|---------|-------------|
| `make build` | Build debug version |
| `make release` | Build optimized release version |
| `make dev` | Build and run in development mode |
| `make clean` | Clean build artifacts |
| `make install` | Install to /usr/local/bin |

## Project Structure

```
silimon/
├── Sources/silimon/
│   ├── App/
│   │   └── AppDelegate.swift      # App lifecycle, status bar setup
│   ├── Models/
│   │   ├── Metrics.swift          # Data structures
│   │   ├── MetricsHistory.swift   # Historical data buffer
│   │   └── Settings.swift         # User preferences
│   ├── Views/
│   │   ├── PopoverView.swift      # Main popover UI
│   │   ├── StatusBarView.swift    # Menu bar custom view
│   │   ├── SettingsView.swift     # Settings panel
│   │   └── *View.swift            # Metric cards (CPU, GPU, etc.)
│   └── Services/
│       ├── MetricsCollector.swift # Main data collection
│       └── PowerMetricsParser.swift # powermetrics parsing
├── Scripts/
│   ├── setup-sudo.sh              # Passwordless powermetrics setup
│   └── uninstall.sh               # Cleanup script
└── Package.swift                   # Swift package manifest
```

## Making Changes

### Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Keep functions focused and concise
- Add comments for non-obvious logic

### Submitting Changes

1. **Fork the repository** and create a new branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and test thoroughly

3. **Commit with a descriptive message**
   ```bash
   git commit -m "feat: add new feature description"
   ```

   Use conventional commit prefixes:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation
   - `refactor:` - Code refactoring
   - `chore:` - Maintenance tasks

4. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Reporting Issues

When reporting bugs, please include:

- macOS version
- Mac model (e.g., MacBook Pro M3)
- Steps to reproduce
- Expected vs actual behavior
- Any error messages from Console.app

## Feature Requests

Feature requests are welcome! Please:

- Check existing issues first to avoid duplicates
- Describe the use case and expected behavior
- Consider if it fits Silimon's goal of being lightweight

## Questions?

Feel free to open an issue for questions or discussion.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
