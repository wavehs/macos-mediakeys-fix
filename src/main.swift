import Cocoa

func printUsage() {
    print("""
    MediaKeysFix - macOS Hardware Media Keys Fix (F7, F8, F9)
    
    Usage: MediaKeysFix [OPTIONS]
    
    Options:
      --status              Show current status of key mapping and autostart
      --enable-login        Enable Launch at Login (start on computer boot)
      --disable-login       Disable Launch at Login
      --apply-keys          Apply HID key mapping for F7, F8, F9
      --reset-keys          Reset keyboard mappings to macOS default
      --play-pause          Send Play / Pause command
      --next                Send Next Track command
      --prev                Send Previous Track command
      --headless, --daemon  Run in background without menu bar item
      --background, --tray  Start minimized to menu bar tray without showing window
      --help, -h            Show this help message
    
    Without options, launches as a native macOS Menu Bar application.
    """)
}

let args = CommandLine.arguments.dropFirst()

if args.contains("--help") || args.contains("-h") {
    printUsage()
    exit(0)
}

if args.contains("--status") {
    let mappingActive = KeyMappingManager.shared.checkIsActive()
    let loginActive = LaunchAtLoginManager.shared.isLaunchAtLoginEnabled()
    print("=== MediaKeysFix Status ===")
    print("HID Key Mapping Active : \(mappingActive ? "YES (F7/F8/F9 mapped)" : "NO (macOS defaults)")")
    print("Start at Login Enabled : \(loginActive ? "YES" : "NO")")
    print("Log file path          : \(MediaRemoteBridge.shared.logPath)")
    exit(0)
}

if args.contains("--enable-login") {
    let success = LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: true)
    print(success ? "✓ Launch at Login enabled." : "✗ Failed to enable Launch at Login.")
    exit(success ? 0 : 1)
}

if args.contains("--disable-login") {
    let success = LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: false)
    print(success ? "✓ Launch at Login disabled." : "✗ Failed to disable Launch at Login.")
    exit(success ? 0 : 1)
}

if args.contains("--apply-keys") {
    let success = KeyMappingManager.shared.applyMapping()
    print(success ? "✓ HID key mapping applied." : "✗ Failed to apply HID key mapping.")
    exit(success ? 0 : 1)
}

if args.contains("--reset-keys") {
    let success = KeyMappingManager.shared.resetMapping()
    print(success ? "✓ Key mapping reset to macOS defaults." : "✗ Failed to reset key mapping.")
    exit(success ? 0 : 1)
}

if args.contains("--play-pause") {
    let ok = MediaRemoteBridge.shared.playPause(source: "CLI")
    print(ok ? "✓ Play/Pause sent." : "✗ Failed to send Play/Pause.")
    exit(ok ? 0 : 1)
}

if args.contains("--next") {
    let ok = MediaRemoteBridge.shared.nextTrack(source: "CLI")
    print(ok ? "✓ Next Track sent." : "✗ Failed to send Next Track.")
    exit(ok ? 0 : 1)
}

if args.contains("--prev") {
    let ok = MediaRemoteBridge.shared.previousTrack(source: "CLI")
    print(ok ? "✓ Previous Track sent." : "✗ Failed to send Previous Track.")
    exit(ok ? 0 : 1)
}

if args.contains("--headless") || args.contains("--daemon") {
    if !SingleInstanceManager.shared.acquireOrActivateExisting() {
        print("MediaKeysFix is already running.")
        exit(0)
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)
    KeyMappingManager.shared.applyMapping()
    HotKeyManager.shared.registerAll()
    MediaRemoteBridge.shared.log("MediaKeysFix running in headless daemon mode")
    app.run()
    exit(0)
}

// Check for single instance:
if !SingleInstanceManager.shared.acquireOrActivateExisting() {
    print("MediaKeysFix is already running. Activated existing window.")
    exit(0)
}

// Default: Menu Bar Application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
