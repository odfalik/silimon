# Silimon

A lightweight macOS menu bar app for monitoring Apple Silicon performance metrics.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Why Silimon?

Unlike other system monitors (like [Stats](https://github.com/exelban/stats)) that use IOKit/SMC sensors, Silimon uses Apple's `powermetrics` tool to show metrics that other apps **cannot display** on Apple Silicon:

| Metric | Stats | Silimon |
|--------|-------|---------|
| CPU/GPU Usage | ✅ | ✅ |
| Memory Usage | ✅ | ✅ |
| **CPU Frequency (E/P cores)** | ❌ | ✅ |
| **Per-component Power (W)** | ❌ | ✅ |
| **ANE Power** | ❌ | ✅ |
| **Package Power** | ❌ | ✅ |

## Features

- **Real-time power monitoring** - See CPU, GPU, and ANE power consumption in watts
- **CPU cluster frequencies** - E-core and P-core frequencies in MHz
- **GPU utilization** - Active usage percentage and frequency
- **Memory pressure** - Used memory, pressure state, and swap
- **Thermal state** - Current thermal pressure level
- **Compact UI** - Minimal menu bar footprint with detailed popover
- **History charts** - Sparkline trends for all metrics

## Installation

### Homebrew (Recommended)

```bash
# Add the tap (first time only)
brew tap odfalik/silimon

# Install
brew install silimon
```

### Build from Source

```bash
git clone https://github.com/odfalik/silimon.git
cd silimon
make install
sudo Scripts/setup-sudo.sh
```

## Usage

```bash
# Start silimon
silimon

# Or run with sudo (if you haven't set up passwordless powermetrics)
sudo silimon
```

Click the menu bar icon to see the detailed metrics popover.

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon Mac (M1, M2, M3, etc.)
- Xcode 14.0+ (for building from source)

## Sudo Access

Silimon requires `sudo` access to run `powermetrics`. During installation, a sudoers entry is created to allow passwordless execution:

```bash
# Manual setup (if needed)
sudo Scripts/setup-sudo.sh
```

This creates `/etc/sudoers.d/silimon` with:
```
%admin ALL=(root) NOPASSWD: /usr/bin/powermetrics
```

### Enable Touch ID for Sudo (Optional)

If you prefer Touch ID authentication:

```bash
sudo sed -i '' '2i\
auth       sufficient     pam_tid.so
' /etc/pam.d/sudo
```

## Uninstall

```bash
# If installed via Homebrew
brew uninstall silimon

# Remove sudoers entry
sudo rm /etc/sudoers.d/silimon

# Or use the uninstall script
sudo Scripts/uninstall.sh
```

## How It Works

Silimon uses Apple's `powermetrics` command-line tool, which provides access to low-level SoC telemetry:

```bash
sudo powermetrics --samplers cpu_power,gpu_power,thermal -f plist
```

The plist output includes:
- CPU cluster idle ratios and frequencies
- GPU idle ratio and frequency
- Per-component power consumption (mW)
- Thermal pressure state

Memory metrics are collected using `vm_stat` and `memory_pressure` (no sudo required).

## Development

```bash
# Build
make build

# Run in development mode
make dev

# Build release version
make release

# Clean build artifacts
make clean
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Inspired by [asitop](https://github.com/tlkh/asitop) - the original Apple Silicon performance monitor.
