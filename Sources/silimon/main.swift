import AppKit
import Foundation

let version = "0.4.3"

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
      -h, --help       Show this help message
      -v, --version    Show version number
      --foreground     Run in foreground (don't daemonize)

    Silimon monitors Apple Silicon performance metrics in your menu bar:
      - CPU/GPU usage and power consumption
      - E-core and P-core frequencies
      - Memory usage and pressure
      - Package and ANE power
      - Battery level, charging state, and time remaining

    Note: Requires sudo access for powermetrics. Run 'sudo Scripts/setup-sudo.sh'
    to enable passwordless operation.

    For more information: https://github.com/odfalik/silimon
    """)
    exit(0)
}

// Daemonize unless --foreground flag is passed
if !args.contains("--foreground") {
    // Get path to self
    guard let executablePath = args.first else {
        fputs("Failed to get executable path\n", stderr)
        exit(1)
    }

    // Relaunch self with --foreground flag
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = ["--foreground"]

    // Detach from terminal
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
        // Detach child from our process group so Ctrl+C won't kill it
        let pid = process.processIdentifier
        setpgid(pid, pid)
        exit(0)  // Parent exits, child continues in background
    } catch {
        fputs("Failed to launch background process: \(error)\n", stderr)
        exit(1)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Hide dock icon - we're a menu bar only app
app.setActivationPolicy(.accessory)

app.run()
