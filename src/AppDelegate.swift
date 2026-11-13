import Cocoa

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 0. If running outside /Applications (e.g. from DMG or Downloads), offer to move
        if checkMoveToApplications() {
            return
        }
        
        MediaRemoteBridge.shared.log("MediaKeysFix application started")
        
        // 1. Clean legacy launch agents if needed
        LaunchAtLoginManager.shared.cleanLegacyAgents()
        
        // 2. Apply HID key remapping
        KeyMappingManager.shared.applyMapping()
        
        // 3. Register Carbon hotkeys
        HotKeyManager.shared.registerAll()
        
        // 4. Setup Menu Bar interface
        StatusBarController.shared.setup()
        
        // 5. Show Window UI if not launched in background
        let isBackground = CommandLine.arguments.contains("--background") || CommandLine.arguments.contains("--silent")
        if !isBackground {
            MainWindowController.shared.show()
        }
        
        // 6. On first launch, politely offer to enable Start at Login
        checkFirstLaunchAutostart()
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainWindowController.shared.show()
        return true
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        MediaRemoteBridge.shared.log("MediaKeysFix terminating: restoring default keymappings")
        KeyMappingManager.shared.resetMapping()
        HotKeyManager.shared.unregisterAll()
    }
    
    private func checkMoveToApplications() -> Bool {
        let bundlePath = Bundle.main.bundlePath
        guard bundlePath.hasSuffix(".app") else { return false }
        
        let homeApps = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        if bundlePath.hasPrefix("/Applications") || bundlePath.hasPrefix(homeApps) {
            return false
        }
        
        // Only prompt if running interactively (not headless/CLI)
        let alert = NSAlert()
        alert.messageText = "Move to Applications Folder?"
        alert.informativeText = "MediaKeysFix works best when installed in your Applications folder so Start at Login and system shortcuts stay permanent.\n\nWould you like to move it now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Run from Current Location")
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let targetDir = FileManager.default.isWritableFile(atPath: "/Applications") ? "/Applications" : homeApps
            try? FileManager.default.createDirectory(atPath: targetDir, withIntermediateDirectories: true)
            
            let destURL = URL(fileURLWithPath: targetDir).appendingPathComponent("MediaKeysFix.app")
            let sourceURL = URL(fileURLWithPath: bundlePath)
            
            do {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
                
                let config = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: destURL, configuration: config) { _, _ in
                    DispatchQueue.main.async {
                        NSApp.terminate(nil)
                    }
                }
                return true
            } catch {
                MediaRemoteBridge.shared.log("Failed to move to \(targetDir): \(error)")
            }
        }
        return false
    }
    
    private func checkFirstLaunchAutostart() {
        let key = "hasPromptedAutoStart"
        if !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            if !LaunchAtLoginManager.shared.isLaunchAtLoginEnabled() {
                let alert = NSAlert()
                alert.messageText = "Enable Start at Login?"
                alert.informativeText = "Would you like MediaKeysFix to start automatically when your Mac turns on so media keys always work?\n\nYou can change this anytime from the menu bar icon."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Enable (Recommended)")
                alert.addButton(withTitle: "Not Now")
                
                NSApp.activate(ignoringOtherApps: true)
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: true)
                    StatusBarController.shared.updateMenuState()
                }
            }
        }
    }
}
