import AppKit
import Foundation

let version = "0.8.2" // x-release-please-version

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
      --debug          Print metrics to console (for validation)

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

// Debug mode: print metrics to console without GUI
if args.contains("--debug") {
    runDebugMode()
    exit(0)
}

// Kill any existing silimon processes (except self)
let myPid = ProcessInfo.processInfo.processIdentifier
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
task.arguments = ["-x", "silimon"]
let pipe = Pipe()
task.standardOutput = pipe
try? task.run()
task.waitUntilExit()
let data = pipe.fileHandleForReading.readDataToEndOfFile()
if let output = String(data: data, encoding: .utf8) {
    for line in output.split(separator: "\n") {
        if let pid = Int32(line), pid != myPid {
            kill(pid, SIGTERM)
        }
    }
}

// Daemonize unless --foreground flag is passed
if !args.contains("--foreground") {
    // Get absolute path to self
    let executablePath: String
    if let arg0 = args.first {
        if arg0.hasPrefix("/") {
            // Already absolute
            executablePath = arg0
        } else if arg0.contains("/") {
            // Relative path - resolve from cwd
            executablePath = FileManager.default.currentDirectoryPath + "/" + arg0
        } else {
            // Just command name - find in PATH
            let pathDirs = (ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin").split(separator: ":")
            executablePath = pathDirs.compactMap { dir -> String? in
                let fullPath = "\(dir)/\(arg0)"
                return FileManager.default.isExecutableFile(atPath: fullPath) ? fullPath : nil
            }.first ?? arg0
        }
    } else {
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
