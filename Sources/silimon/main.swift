import AppKit
import Foundation

let version = "0.7.0" // x-release-please-version

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
        exit(0)  // Parent exits immediately, child continues in background
    } catch {
        fputs("Failed to launch background process: \(error)\n", stderr)
        exit(1)
    }
}

// When running as the background process, fully detach from the terminal
if args.contains("--foreground") {
    // Create a new session (detach from controlling terminal)
    _ = setsid()

    // Ignore terminal signals so Ctrl+C won't kill us
    signal(SIGINT, SIG_IGN)
    signal(SIGHUP, SIG_IGN)
    signal(SIGTSTP, SIG_IGN)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Hide dock icon - we're a menu bar only app
app.setActivationPolicy(.accessory)

app.run()
