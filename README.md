# Silimon

<img width="348" height="478" alt="demo screenshot" src="https://github.com/user-attachments/assets/6d42c7e4-9101-4628-b074-5bc688366b15" />

A lightweight macOS menu bar app for monitoring Apple Silicon performance metrics.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Why Silimon?

Silimon uses Apple's IOReport API to show metrics that other apps **cannot display** on Apple Silicon - no sudo required:

| Metric | Others | Silimon |
|--------|--------|---------|
| CPU/GPU Usage | ✅ | ✅ |
| Memory Usage | ✅ | ✅ |
| **CPU Frequency (E/P cores)** | ❌ | ✅ |
| **Per-component Power (W)** | ❌ | ✅ |
| **ANE Power** | ❌ | ✅ |
| **Package Power** | ❌ | ✅ |

## Features

- **Real-time power monitoring** - CPU, GPU, and ANE power consumption in watts
- **CPU cluster frequencies** - E-core and P-core frequencies in MHz
- **GPU utilization** - Active usage percentage and frequency
- **Memory pressure** - Used memory, pressure state, and swap
- **Thermal state** - Current thermal pressure level
- **History charts** - Sparkline trends for all metrics
- **No sudo required** - Uses IOReport API for direct access to SoC metrics

## Installation

```bash
# Install via Homebrew
brew tap odfalik/silimon
brew install silimon

# Start silimon
silimon
```

Click the menu bar icon to view metrics. Use the gear icon for settings (sampling rate, launch at login, etc.).

<details>
<summary><strong>Build from Source</strong></summary>

```bash
git clone https://github.com/odfalik/silimon.git
cd silimon
make install
silimon
```

</details>

<details>
<summary><strong>Requirements</strong></summary>

- macOS 13.0 (Ventura) or later
- Apple Silicon Mac (M1, M2, M3, M4, etc.)
- Xcode 14.0+ (for building from source)

</details>

<details>
<summary><strong>How It Works</strong></summary>

Silimon uses Apple's IOReport API for low-level SoC telemetry. This provides:

- CPU cluster frequencies (E-core and P-core)
- Per-component power consumption (CPU, GPU, ANE, DRAM)
- GPU frequency and utilization
- Thermal state

Memory metrics use the Mach kernel API (no special permissions required).

Unlike tools that use `powermetrics`, Silimon accesses IOReport directly without requiring sudo, making it ideal for a menu bar app.

</details>

<details>
<summary><strong>Uninstall</strong></summary>

```bash
brew uninstall silimon
rm ~/Library/LaunchAgents/com.silimon.app.plist  # if launch at login was enabled
```

</details>

<details>
<summary><strong>Development</strong></summary>

```bash
make build      # Build
make dev        # Run in development mode
make release    # Build release version
make clean      # Clean build artifacts
```

</details>

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

- Inspired by [asitop](https://github.com/tlkh/asitop) - the original Apple Silicon performance monitor
- IOReport implementation based on [mactop](https://github.com/metaspartan/mactop) - a Go-based macOS system monitor
