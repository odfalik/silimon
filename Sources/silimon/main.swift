import AppKit
import Foundation

let version = "0.1.0"

// Handle command line arguments
let args = CommandLine.arguments
if args.contains("--version") || args.contains("-v") {
    print("silimon \(version)")
    exit(0)
}

if args.contains("--help") || args.contains("-h") {
    print("""
    silimon - Apple Silicon Performance Monitor

    Usage: silimon [options]

    Options:
      -h, --help     Show this help message
      -v, --version  Show version number

    Silimon monitors Apple Silicon performance metrics in your menu bar:
      - CPU/GPU usage and power consumption
      - E-core and P-core frequencies
      - Memory usage and pressure
      - Package and ANE power

    Note: Requires sudo access for powermetrics. Run 'sudo Scripts/setup-sudo.sh'
    to enable passwordless operation.

    For more information: https://github.com/odfalik/silimon
    """)
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Hide dock icon - we're a menu bar only app
app.setActivationPolicy(.accessory)

app.run()
