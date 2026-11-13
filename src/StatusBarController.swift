import Cocoa

public final class StatusBarController: NSObject, NSMenuDelegate {
    public static let shared = StatusBarController()
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    
    private var statusMenuItem: NSMenuItem!
    private var enableMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!
    private var fallbacksMenuItem: NSMenuItem!
    
    override private init() {
        super.init()
    }
    
    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let icon = createIcon()
            button.image = icon
            button.imagePosition = .imageOnly
            button.toolTip = "Media Keys Fix (Click to open menu)"
        }
        
        menu = NSMenu()
        menu.delegate = self
        buildMenu()
        statusItem.menu = menu
    }
    
    private func createIcon() -> NSImage {
        // Try system SF symbol first
        if #available(macOS 11.0, *),
           let sysImg = NSImage(systemSymbolName: "playpause", accessibilityDescription: "Media Keys Fix") {
            sysImg.isTemplate = true
            return sysImg
        }
        
        // Fallback: Custom crisp vector icon (Play triangle + Pause bars)
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            
            // Play triangle (left)
            let play = NSBezierPath()
            play.move(to: NSPoint(x: 2, y: 4))
            play.line(to: NSPoint(x: 8.5, y: 9))
            play.line(to: NSPoint(x: 2, y: 14))
            play.close()
            play.fill()
            
            // Pause bars (right)
            let bar1 = NSRect(x: 10.5, y: 4, width: 2.2, height: 10)
            let bar2 = NSRect(x: 14.5, y: 4, width: 2.2, height: 10)
            NSBezierPath(roundedRect: bar1, xRadius: 1, yRadius: 1).fill()
            NSBezierPath(roundedRect: bar2, xRadius: 1, yRadius: 1).fill()
            
            return true
        }
        img.isTemplate = true
        return img
    }
    
    private func buildMenu() {
        menu.removeAllItems()
        
        // 1. App Title
        let titleItem = NSMenuItem(title: "Media Keys Fix v1.0.0", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        if let font = NSFont.boldSystemFont(ofSize: 13) as NSFont? {
            titleItem.attributedTitle = NSAttributedString(string: "Media Keys Fix v1.0.0", attributes: [.font: font])
        }
        menu.addItem(titleItem)
        
        // 2. Open Settings Window
        let openWindowItem = NSMenuItem(title: "Open MediaKeysFix Window...", action: #selector(openWindowAction), keyEquivalent: "o")
        openWindowItem.target = self
        menu.addItem(openWindowItem)
        
        // 3. Status display
        statusMenuItem = NSMenuItem(title: "● Status: Active", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Enable / Disable toggle
        enableMenuItem = NSMenuItem(title: "Remap F7 / F8 / F9 Keys", action: #selector(toggleEnableAction), keyEquivalent: "")
        enableMenuItem.target = self
        enableMenuItem.state = .on
        menu.addItem(enableMenuItem)
        
        // 5. Start at Login toggle
        launchAtLoginMenuItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLaunchAtLoginAction), keyEquivalent: "")
        launchAtLoginMenuItem.target = self
        menu.addItem(launchAtLoginMenuItem)
        
        // 6. Fallback Hotkeys toggle
        fallbacksMenuItem = NSMenuItem(title: "Fallback Shortcuts (⌃⌥Space, ⌃⌥←, ⌃⌥→)", action: #selector(toggleFallbacksAction), keyEquivalent: "")
        fallbacksMenuItem.target = self
        fallbacksMenuItem.state = .on
        menu.addItem(fallbacksMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 7. Media Controls
        let mediaSubmenu = NSMenu(title: "Media Controls")
        
        let playPauseItem = NSMenuItem(title: "Play / Pause", action: #selector(playPauseAction), keyEquivalent: "")
        playPauseItem.target = self
        mediaSubmenu.addItem(playPauseItem)
        
        let nextItem = NSMenuItem(title: "Next Track", action: #selector(nextAction), keyEquivalent: "")
        nextItem.target = self
        mediaSubmenu.addItem(nextItem)
        
        let prevItem = NSMenuItem(title: "Previous Track", action: #selector(prevAction), keyEquivalent: "")
        prevItem.target = self
        mediaSubmenu.addItem(prevItem)
        
        let controlsParent = NSMenuItem(title: "Quick Media Controls", action: nil, keyEquivalent: "")
        controlsParent.submenu = mediaSubmenu
        menu.addItem(controlsParent)
        
        menu.addItem(NSMenuItem.separator())
        
        // 8. Re-apply Key Mapping
        let reapplyItem = NSMenuItem(title: "Re-apply Key Mapping", action: #selector(reapplyAction), keyEquivalent: "r")
        reapplyItem.target = self
        menu.addItem(reapplyItem)
        
        // 9. View Logs
        let logsItem = NSMenuItem(title: "View Logs...", action: #selector(viewLogsAction), keyEquivalent: "l")
        logsItem.target = self
        menu.addItem(logsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 10. Close to Tray / Full Quit
        let hideWindowItem = NSMenuItem(title: "Close Window to Tray", action: #selector(hideWindowAction), keyEquivalent: "w")
        hideWindowItem.target = self
        menu.addItem(hideWindowItem)
        
        let quitItem = NSMenuItem(title: "Full Quit (Exit App)", action: #selector(fullQuitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        updateMenuState()
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        updateMenuState()
    }
    
    public func updateMenuState() {
        let isEnabled = HotKeyManager.shared.isRegistered
        statusMenuItem.title = isEnabled ? "● Status: Active" : "○ Status: Inactive"
        enableMenuItem.state = isEnabled ? .on : .off
        
        let loginEnabled = LaunchAtLoginManager.shared.isLaunchAtLoginEnabled()
        launchAtLoginMenuItem.state = loginEnabled ? .on : .off
        
        fallbacksMenuItem.state = HotKeyManager.shared.fallbacksEnabled ? .on : .off
    }
    
    @objc public func openWindowAction() {
        MainWindowController.shared.show()
    }
    
    @objc private func hideWindowAction() {
        MainWindowController.shared.closeToTray()
    }
    
    @objc private func toggleEnableAction() {
        if HotKeyManager.shared.isRegistered {
            HotKeyManager.shared.unregisterAll()
            KeyMappingManager.shared.resetMapping()
        } else {
            KeyMappingManager.shared.applyMapping()
            HotKeyManager.shared.registerAll()
        }
        updateMenuState()
        MainWindowController.shared.updateUIState()
    }
    
    @objc private func toggleLaunchAtLoginAction() {
        let currentState = LaunchAtLoginManager.shared.isLaunchAtLoginEnabled()
        let newState = !currentState
        _ = LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: newState)
        updateMenuState()
        MainWindowController.shared.updateUIState()
    }
    
    @objc private func toggleFallbacksAction() {
        let newState = !HotKeyManager.shared.fallbacksEnabled
        HotKeyManager.shared.setFallbacks(enabled: newState)
        updateMenuState()
        MainWindowController.shared.updateUIState()
    }
    
    @objc private func playPauseAction() {
        MediaRemoteBridge.shared.playPause(source: "Menu Bar")
    }
    
    @objc private func nextAction() {
        MediaRemoteBridge.shared.nextTrack(source: "Menu Bar")
    }
    
    @objc private func prevAction() {
        MediaRemoteBridge.shared.previousTrack(source: "Menu Bar")
    }
    
    @objc private func reapplyAction() {
        _ = KeyMappingManager.shared.applyMapping()
        HotKeyManager.shared.registerAll()
        updateMenuState()
        MainWindowController.shared.updateUIState()
    }
    
    @objc private func viewLogsAction() {
        let logURL = URL(fileURLWithPath: MediaRemoteBridge.shared.logPath)
        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil, attributes: nil)
        }
        NSWorkspace.shared.open(logURL)
    }
    
    @objc private func fullQuitAction() {
        MainWindowController.shared.fullQuit()
    }
}
