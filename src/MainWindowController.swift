import Cocoa

public final class MainWindowController: NSObject, NSWindowDelegate {
    public static let shared = MainWindowController()
    
    private var window: NSWindow!
    
    // UI Elements
    private var statusDot: NSView!
    private var statusTitleLabel: NSTextField!
    private var statusDescLabel: NSTextField!
    private var enableSwitch: NSSwitch!
    
    private var autostartCheckbox: NSButton!
    private var fallbackCheckbox: NSButton!
    
    private var isSetup = false
    
    override private init() {
        super.init()
    }
    
    public func setup() {
        guard !isSetup else { return }
        isSetup = true
        
        let width: CGFloat = 430
        let height: CGFloat = 450
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MediaKeysFix"
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        contentView.wantsLayer = true
        window.contentView = contentView
        
        buildUI(in: contentView, width: width, height: height)
        updateUIState()
    }
    
    private func buildUI(in root: NSView, width: CGFloat, height: CGFloat) {
        // 1. Header (y: 370..435)
        let iconView = NSImageView(frame: NSRect(x: 20, y: height - 68, width: 48, height: 48))
        if let icon = NSApp.applicationIconImage ?? NSImage(named: "AppIcon") {
            iconView.image = icon
        } else if #available(macOS 11.0, *) {
            iconView.image = NSImage(systemSymbolName: "playpause", accessibilityDescription: "Icon")
        }
        root.addSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: "Media Keys Fix")
        titleLabel.frame = NSRect(x: 78, y: height - 48, width: 330, height: 26)
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        root.addSubview(titleLabel)
        
        let subtitleLabel = NSTextField(labelWithString: "Hardware fix for physical F7, F8, F9 media keys")
        subtitleLabel.frame = NSRect(x: 79, y: height - 70, width: 330, height: 18)
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor
        root.addSubview(subtitleLabel)
        
        // 2. Card 1: Main Status Box (y: 275..360)
        let statusCard = createCard(frame: NSRect(x: 20, y: height - 170, width: width - 40, height: 85))
        root.addSubview(statusCard)
        
        // Status dot
        statusDot = NSView(frame: NSRect(x: 16, y: 48, width: 12, height: 12))
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 6
        statusCard.addSubview(statusDot)
        
        statusTitleLabel = NSTextField(labelWithString: "Fix Active")
        statusTitleLabel.frame = NSRect(x: 36, y: 43, width: 230, height: 22)
        statusTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        statusCard.addSubview(statusTitleLabel)
        
        statusDescLabel = NSTextField(labelWithString: "F7, F8, F9 are routed to media players")
        statusDescLabel.frame = NSRect(x: 16, y: 18, width: 270, height: 18)
        statusDescLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        statusDescLabel.textColor = .secondaryLabelColor
        statusCard.addSubview(statusDescLabel)
        
        enableSwitch = NSSwitch(frame: NSRect(x: statusCard.frame.width - 60, y: 38, width: 45, height: 26))
        enableSwitch.target = self
        enableSwitch.action = #selector(onToggleSwitch(_:))
        statusCard.addSubview(enableSwitch)
        
        // 3. Card 2: Options Box (y: 165..265)
        let optionsCard = createCard(frame: NSRect(x: 20, y: height - 275, width: width - 40, height: 95))
        root.addSubview(optionsCard)
        
        autostartCheckbox = NSButton(checkboxWithTitle: "Start at Login (Autostart on boot)", target: self, action: #selector(onToggleAutostart(_:)))
        autostartCheckbox.frame = NSRect(x: 16, y: 56, width: 350, height: 22)
        autostartCheckbox.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        optionsCard.addSubview(autostartCheckbox)
        
        let autostartSub = NSTextField(labelWithString: "Starts automatically in tray when Mac turns on")
        autostartSub.frame = NSRect(x: 34, y: 38, width: 330, height: 16)
        autostartSub.font = NSFont.systemFont(ofSize: 10.5, weight: .regular)
        autostartSub.textColor = .secondaryLabelColor
        optionsCard.addSubview(autostartSub)
        
        fallbackCheckbox = NSButton(checkboxWithTitle: "Fallback Shortcuts (Ctrl + Option + Space)", target: self, action: #selector(onToggleFallbacks(_:)))
        fallbackCheckbox.frame = NSRect(x: 16, y: 14, width: 350, height: 20)
        fallbackCheckbox.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        optionsCard.addSubview(fallbackCheckbox)
        
        // 4. Card 3: Quick Media Test Buttons (y: 95..155)
        let testCard = createCard(frame: NSRect(x: 20, y: height - 345, width: width - 40, height: 60))
        root.addSubview(testCard)
        
        let testTitle = NSTextField(labelWithString: "Test Keys:")
        testTitle.frame = NSRect(x: 14, y: 20, width: 75, height: 18)
        testTitle.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        testTitle.textColor = .secondaryLabelColor
        testCard.addSubview(testTitle)
        
        let btnPrev = NSButton(title: "⏮ F7 Prev", target: self, action: #selector(onTestPrev))
        btnPrev.frame = NSRect(x: 90, y: 14, width: 88, height: 32)
        btnPrev.bezelStyle = .rounded
        testCard.addSubview(btnPrev)
        
        let btnPlay = NSButton(title: "⏯ F8 Play", target: self, action: #selector(onTestPlay))
        btnPlay.frame = NSRect(x: 184, y: 14, width: 88, height: 32)
        btnPlay.bezelStyle = .rounded
        testCard.addSubview(btnPlay)
        
        let btnNext = NSButton(title: "⏭ F9 Next", target: self, action: #selector(onTestNext))
        btnNext.frame = NSRect(x: 278, y: 14, width: 88, height: 32)
        btnNext.bezelStyle = .rounded
        testCard.addSubview(btnNext)
        
        // 5. Tray Hint (y: 62)
        let trayHint = NSTextField(labelWithString: "💡 App stays active in the menu bar tray (⏯). To stop completely, click Full Quit.")
        trayHint.frame = NSRect(x: 20, y: 62, width: width - 40, height: 16)
        trayHint.font = NSFont.systemFont(ofSize: 10.5, weight: .medium)
        trayHint.textColor = .secondaryLabelColor
        root.addSubview(trayHint)
        
        // 6. Action Buttons: Full Quit & Close to Tray (y: 18..52)
        let btnWidth = (width - 50) / 2.0
        
        let btnQuit = NSButton(title: "Full Quit", target: self, action: #selector(onFullQuitClicked))
        btnQuit.frame = NSRect(x: 20, y: 18, width: btnWidth, height: 34)
        btnQuit.bezelStyle = .rounded
        root.addSubview(btnQuit)
        
        let btnCloseTray = NSButton(title: "Close to Tray", target: self, action: #selector(onCloseToTrayClicked))
        btnCloseTray.frame = NSRect(x: 30 + btnWidth, y: 18, width: btnWidth, height: 34)
        btnCloseTray.bezelStyle = .rounded
        btnCloseTray.keyEquivalent = "\r" // Enter key default
        root.addSubview(btnCloseTray)
    }
    
    private func createCard(frame: NSRect) -> NSBox {
        let box = NSBox(frame: frame)
        box.boxType = .custom
        box.cornerRadius = 10
        box.borderWidth = 1
        box.borderColor = NSColor.separatorColor.withAlphaComponent(0.3)
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5)
        return box
    }
    
    public func updateUIState() {
        guard isSetup else { return }
        
        let isEnabled = HotKeyManager.shared.isRegistered
        enableSwitch.state = isEnabled ? .on : .off
        statusDot.layer?.backgroundColor = isEnabled ? NSColor.systemGreen.cgColor : NSColor.systemGray.cgColor
        statusTitleLabel.stringValue = isEnabled ? "Fix Active" : "Fix Disabled"
        statusDescLabel.stringValue = isEnabled
            ? "F7, F8, F9 are captured & routed to media"
            : "Keyboard is in native macOS default mode"
        
        let loginEnabled = LaunchAtLoginManager.shared.isLaunchAtLoginEnabled()
        autostartCheckbox.state = loginEnabled ? .on : .off
        
        fallbackCheckbox.state = HotKeyManager.shared.fallbacksEnabled ? .on : .off
    }
    
    public func show() {
        setup()
        updateUIState()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // Window delegate: Red close button (X) closes window to tray!
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        closeToTray()
        return false
    }
    
    @objc public func closeToTray() {
        if window != nil {
            window.orderOut(nil)
        }
    }
    
    @objc public func fullQuit() {
        MediaRemoteBridge.shared.log("Full Quit requested by user: restoring defaults and exiting")
        KeyMappingManager.shared.resetMapping()
        HotKeyManager.shared.unregisterAll()
        NSApp.terminate(nil)
    }
    
    // UI Button Handlers
    @objc private func onFullQuitClicked() {
        fullQuit()
    }
    
    @objc private func onCloseToTrayClicked() {
        closeToTray()
    }
    
    @objc private func onToggleSwitch(_ sender: NSSwitch) {
        if sender.state == .on {
            KeyMappingManager.shared.applyMapping()
            HotKeyManager.shared.registerAll()
        } else {
            HotKeyManager.shared.unregisterAll()
            KeyMappingManager.shared.resetMapping()
        }
        updateUIState()
        StatusBarController.shared.updateMenuState()
    }
    
    @objc private func onToggleAutostart(_ sender: NSButton) {
        let enable = (sender.state == .on)
        LaunchAtLoginManager.shared.setLaunchAtLogin(enabled: enable)
        updateUIState()
        StatusBarController.shared.updateMenuState()
    }
    
    @objc private func onToggleFallbacks(_ sender: NSButton) {
        let enable = (sender.state == .on)
        HotKeyManager.shared.setFallbacks(enabled: enable)
        updateUIState()
        StatusBarController.shared.updateMenuState()
    }
    
    @objc private func onTestPrev() {
        MediaRemoteBridge.shared.previousTrack(source: "UI Test")
    }
    
    @objc private func onTestPlay() {
        MediaRemoteBridge.shared.playPause(source: "UI Test")
    }
    
    @objc private func onTestNext() {
        MediaRemoteBridge.shared.nextTrack(source: "UI Test")
    }
}
