import Cocoa

public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()
    
    public let serviceLabel = "com.user.mediakeysfix"
    
    private var launchAgentsDir: URL {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }
    
    public var plistURL: URL {
        return launchAgentsDir.appendingPathComponent("\(serviceLabel).plist")
    }
    
    private init() {}
    
    public func isLaunchAtLoginEnabled() -> Bool {
        return FileManager.default.fileExists(atPath: plistURL.path)
    }
    
    public func targetExecutablePath() -> String {
        // If /Applications/MediaKeysFix.app exists, prefer that canonical path
        let defaultAppPath = "/Applications/MediaKeysFix.app/Contents/MacOS/MediaKeysFix"
        if FileManager.default.fileExists(atPath: defaultAppPath) {
            return defaultAppPath
        }
        
        let userAppPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/MediaKeysFix.app/Contents/MacOS/MediaKeysFix").path
        if FileManager.default.fileExists(atPath: userAppPath) {
            return userAppPath
        }
        
        if let exePath = Bundle.main.executablePath {
            return exePath
        }
        return CommandLine.arguments[0]
    }
    
    @discardableResult
    public func setLaunchAtLogin(enabled: Bool) -> Bool {
        if enabled {
            return enable()
        } else {
            return disable()
        }
    }
    
    private func enable() -> Bool {
        cleanLegacyAgents()
        
        let fm = FileManager.default
        let dir = launchAgentsDir
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        
        let exe = targetExecutablePath()
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(serviceLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(exe)</string>
                <string>--background</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>StandardErrorPath</key>
            <string>/tmp/mediakeyd.err</string>
            <key>StandardOutPath</key>
            <string>/tmp/mediakeyd.out</string>
        </dict>
        </plist>
        """
        
        do {
            try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
            
            // Reload with launchctl
            let unloadTask = Process()
            unloadTask.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            unloadTask.arguments = ["unload", plistURL.path]
            unloadTask.standardOutput = FileHandle.nullDevice
            unloadTask.standardError = FileHandle.nullDevice
            try? unloadTask.run()
            unloadTask.waitUntilExit()
            
            let loadTask = Process()
            loadTask.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            loadTask.arguments = ["load", plistURL.path]
            loadTask.standardOutput = FileHandle.nullDevice
            loadTask.standardError = FileHandle.nullDevice
            try loadTask.run()
            loadTask.waitUntilExit()
            
            MediaRemoteBridge.shared.log("Launch at Login enabled successfully")
            return true
        } catch {
            MediaRemoteBridge.shared.log("Failed to write LaunchAgent plist: \(error)")
            return false
        }
    }
    
    private func disable() -> Bool {
        let unloadTask = Process()
        unloadTask.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        unloadTask.arguments = ["unload", plistURL.path]
        unloadTask.standardOutput = FileHandle.nullDevice
        unloadTask.standardError = FileHandle.nullDevice
        try? unloadTask.run()
        unloadTask.waitUntilExit()
        
        try? FileManager.default.removeItem(at: plistURL)
        MediaRemoteBridge.shared.log("Launch at Login disabled")
        return true
    }
    
    public func cleanLegacyAgents() {
        let legacyNames = [
            "com.user.mediakeyd.plist",
            "com.user.hidutilKeyMapping.plist"
        ]
        let fm = FileManager.default
        for name in legacyNames {
            let legacyURL = launchAgentsDir.appendingPathComponent(name)
            if fm.fileExists(atPath: legacyURL.path) {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                task.arguments = ["unload", legacyURL.path]
                task.standardOutput = FileHandle.nullDevice
                task.standardError = FileHandle.nullDevice
                try? task.run()
                task.waitUntilExit()
                try? fm.removeItem(at: legacyURL)
                MediaRemoteBridge.shared.log("Cleaned up legacy agent: \(name)")
            }
        }
    }
}
