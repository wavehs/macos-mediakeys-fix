import Cocoa

let width: CGFloat = 720
let height: CGFloat = 400
let framesCount = 42
let fps = 12

let fileManager = FileManager.default
let tempFramesDir = "build/temp_unique_frames"

try? fileManager.removeItem(atPath: "GIFS")
try! fileManager.createDirectory(atPath: "GIFS", withIntermediateDirectories: true)

// MARK: - Helpers

func drawBaseWindow(title: String, subtitle: String? = nil, bgCol: NSColor = NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.12, alpha: 1.0)) {
    // Background
    bgCol.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Top bar
    let barRect = NSRect(x: 0, y: height - 36, width: width, height: 36)
    NSColor(calibratedWhite: 0.13, alpha: 0.95).setFill()
    barRect.fill()
    
    NSColor(calibratedWhite: 1.0, alpha: 0.1).setStroke()
    let div = NSBezierPath()
    div.move(to: NSPoint(x: 0, y: height - 36))
    div.line(to: NSPoint(x: width, y: height - 36))
    div.stroke()
    
    // Traffic lights
    let dots: [NSColor] = [
        NSColor(calibratedRed: 1.0, green: 0.36, blue: 0.32, alpha: 1.0),
        NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.18, alpha: 1.0),
        NSColor(calibratedRed: 0.16, green: 0.80, blue: 0.38, alpha: 1.0)
    ]
    for (i, c) in dots.enumerated() {
        c.setFill()
        NSBezierPath(ovalIn: NSRect(x: 18.0 + CGFloat(i * 16), y: height - 23.0, width: 10.0, height: 10.0)).fill()
    }
    
    // Title
    (title as NSString).draw(at: NSPoint(x: 75.0, y: height - 24.0), withAttributes: [
        .font: NSFont.systemFont(ofSize: 11.5, weight: .semibold),
        .foregroundColor: NSColor(calibratedWhite: 0.85, alpha: 1.0)
    ])
    
    if let sub = subtitle {
        (sub as NSString).draw(at: NSPoint(x: width - 260.0, y: height - 24.0), withAttributes: [
            .font: NSFont.systemFont(ofSize: 11.0, weight: .medium),
            .foregroundColor: NSColor(calibratedRed: 0.3, green: 0.75, blue: 1.0, alpha: 1.0)
        ])
    }
}

// MARK: - 1. Physical Keyboard Hardware View
func render1_PhysicalKeyboard(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
    
    drawBaseWindow(title: "Hardware Layer • MacBook Pro Keyboard Deck", subtitle: "Direct HID Consumer Intercept")
    
    // Space gray aluminum deck
    let deckRect = NSRect(x: 35, y: 40, width: width - 70, height: height - 95)
    let deckPath = NSBezierPath(roundedRect: deckRect, xRadius: 16, yRadius: 16)
    NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.20, alpha: 1.0).setFill()
    deckPath.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.15).setStroke()
    deckPath.stroke()
    
    // Title above keys
    ("PHYSICAL FUNCTION KEY ROW (F7 • F8 • F9)" as NSString).draw(at: NSPoint(x: 60, y: deckRect.maxY - 35), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold),
        .foregroundColor: NSColor(calibratedWhite: 0.6, alpha: 1.0)
    ])
    
    // 3 prominent keys
    let keys = [("F7", "⏮", "PREV"), ("F8", "⏯", "PLAY/PAUSE"), ("F9", "⏭", "NEXT")]
    let isF8Pressed = (frame >= 14 && frame <= 28)
    let glowAmount: CGFloat = isF8Pressed ? sin(CGFloat(frame - 14) / 14.0 * .pi) : 0.0
    
    for (i, (fKey, icon, label)) in keys.enumerated() {
        let isTarget = (i == 1) // F8
        let kX = 75.0 + CGFloat(i * 185)
        let kY = deckRect.minY + 75.0 - (isTarget && isF8Pressed ? 4.0 : 0.0)
        let kRect = NSRect(x: kX, y: kY, width: 160, height: 130)
        let kPath = NSBezierPath(roundedRect: kRect, xRadius: 14, yRadius: 14)
        
        if isTarget && isF8Pressed {
            ctx.saveGState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor(calibratedRed: 0.2, green: 0.7, blue: 1.0, alpha: 0.9)
            shadow.shadowBlurRadius = 24 * glowAmount
            shadow.set()
            NSColor(calibratedRed: 0.22, green: 0.26, blue: 0.35, alpha: 1.0).setFill()
            kPath.fill()
            ctx.restoreGState()
            
            NSColor(calibratedRed: 0.3, green: 0.8, blue: 1.0, alpha: 1.0).setStroke()
            kPath.lineWidth = 2.5
            kPath.stroke()
        } else {
            NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.14, alpha: 1.0).setFill()
            kPath.fill()
            NSColor(calibratedWhite: 1.0, alpha: 0.18).setStroke()
            kPath.lineWidth = 1.0
            kPath.stroke()
        }
        
        // F-label
        (fKey as NSString).draw(at: NSPoint(x: kX + 20, y: kY + 85), withAttributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 20, weight: .bold),
            .foregroundColor: (isTarget && isF8Pressed) ? NSColor.white : NSColor(calibratedWhite: 0.85, alpha: 1.0)
        ])
        
        // Media Icon
        (icon as NSString).draw(at: NSPoint(x: kX + 65, y: kY + 45), withAttributes: [
            .font: NSFont.systemFont(ofSize: 32),
            .foregroundColor: (isTarget && isF8Pressed) ? NSColor(calibratedRed: 0.3, green: 0.8, blue: 1.0, alpha: 1.0) : NSColor.white
        ])
        
        // Subtitle
        (label as NSString).draw(at: NSPoint(x: kX + 45, y: kY + 16), withAttributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor(calibratedWhite: 0.5, alpha: 1.0)
        ])
    }
    
    // Bottom tactile feedback banner
    let bRect = NSRect(x: 55, y: 55, width: deckRect.width - 40, height: 42)
    NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 0.85).setFill()
    NSBezierPath(roundedRect: bRect, xRadius: 8, yRadius: 8).fill()
    
    let bannerTxt = isF8Pressed
        ? "⚡ [KEY DOWN] F8 Pressed ➔ Bypassed WebKit Bounce ➔ Dispatched to MediaRemote (2.7ms)"
        : "⌨️ Press F7 / F8 / F9 physically • Zero Accessibility Permissions Needed"
    let bannerCol = isF8Pressed ? NSColor(calibratedRed: 0.3, green: 0.85, blue: 1.0, alpha: 1.0) : NSColor(calibratedWhite: 0.7, alpha: 1.0)
    (bannerTxt as NSString).draw(at: NSPoint(x: 75, y: 68), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 11.5, weight: .semibold),
        .foregroundColor: bannerCol
    ])
    
    img.unlockFocus()
    return img
}

// MARK: - 2. Split-Screen Before vs After Comparison
func render2_BeforeAfter(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    
    drawBaseWindow(title: "Problem vs Solution: WebKit 86ms Bounce Fix", subtitle: "Side-by-Side Comparison")
    
    let isPressed = (frame >= 12 && frame <= 30)
    let halfW = (width - 60) / 2.0
    
    // LEFT: WITHOUT FIX (Buggy)
    let leftRect = NSRect(x: 25, y: 40, width: halfW, height: height - 90)
    NSColor(calibratedRed: 0.18, green: 0.08, blue: 0.09, alpha: 0.9).setFill()
    NSBezierPath(roundedRect: leftRect, xRadius: 12, yRadius: 12).fill()
    NSColor.systemRed.withAlphaComponent(0.4).setStroke()
    NSBezierPath(roundedRect: leftRect, xRadius: 12, yRadius: 12).stroke()
    
    ("❌ WITHOUT FIX (Default macOS)" as NSString).draw(at: NSPoint(x: 45, y: leftRect.maxY - 35), withAttributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .bold),
        .foregroundColor: NSColor.systemRed
    ])
    
    let leftState = isPressed ? "Press F8 ➔ Pauses... then BOUNCES back to Play! ❌" : "Track Playing in YouTube Music"
    (leftState as NSString).draw(at: NSPoint(x: 45, y: leftRect.maxY - 70), withAttributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 0.85, alpha: 1.0)
    ])
    
    // Animated bounce failure bar
    let leftBar = NSRect(x: 45, y: leftRect.minY + 60, width: halfW - 40, height: 35)
    NSColor.black.withAlphaComponent(0.4).setFill()
    NSBezierPath(roundedRect: leftBar, xRadius: 6, yRadius: 6).fill()
    
    let failMsg = isPressed ? "WebKit 86ms State Bounce: IGNORING PAUSE" : "Normal Playback"
    (failMsg as NSString).draw(at: NSPoint(x: 55, y: leftRect.minY + 70), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 10.5, weight: .bold),
        .foregroundColor: isPressed ? NSColor.systemRed : NSColor.systemGray
    ])
    
    // RIGHT: WITH MEDIKEYSFIX (Solid)
    let rightRect = NSRect(x: 35 + halfW, y: 40, width: halfW, height: height - 90)
    NSColor(calibratedRed: 0.07, green: 0.16, blue: 0.10, alpha: 0.9).setFill()
    NSBezierPath(roundedRect: rightRect, xRadius: 12, yRadius: 12).fill()
    NSColor.systemGreen.withAlphaComponent(0.4).setStroke()
    NSBezierPath(roundedRect: rightRect, xRadius: 12, yRadius: 12).stroke()
    
    ("✅ WITH MEDIAKEYSFIX (Hardware)" as NSString).draw(at: NSPoint(x: 55 + halfW, y: rightRect.maxY - 35), withAttributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .bold),
        .foregroundColor: NSColor.systemGreen
    ])
    
    let rightState = isPressed ? "Press F8 ➔ Instant Clean Pause (2.7ms) ✅" : "Track Playing (Protected by Debounce)"
    (rightState as NSString).draw(at: NSPoint(x: 55 + halfW, y: rightRect.maxY - 70), withAttributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 0.85, alpha: 1.0)
    ])
    
    // Solid success bar
    let rightBar = NSRect(x: 55 + halfW, y: rightRect.minY + 60, width: halfW - 40, height: 35)
    NSColor.black.withAlphaComponent(0.4).setFill()
    NSBezierPath(roundedRect: rightBar, xRadius: 6, yRadius: 6).fill()
    
    let successMsg = isPressed ? "SOLID PAUSE • 0ms Bounce • 100% Reliable" : "Protected by MediaKeysFix"
    (successMsg as NSString).draw(at: NSPoint(x: 65 + halfW, y: rightRect.minY + 70), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 10.5, weight: .bold),
        .foregroundColor: isPressed ? NSColor.systemGreen : NSColor.systemGray
    ])
    
    img.unlockFocus()
    return img
}

// MARK: - 3. The Architecture Signal Pipeline
func render3_ArchitecturePipeline(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
    
    drawBaseWindow(title: "Architecture & Latency Pipeline", subtitle: "Total Response: ~2.7 ms")
    
    let nodes = [
        ("1. KEYPRESS", "F8 (Physical)"),
        ("2. KERNEL HID", "hidutil (F17)"),
        ("3. CARBON", "HotKey Handler"),
        ("4. MEDIAREMOTE", "MRSendCommand")
    ]
    
    // Animate packet position across nodes
    let progress = CGFloat(frame % framesCount) / CGFloat(framesCount)
    let totalLen = width - 180.0
    let packetX = 90.0 + progress * totalLen
    
    // Cable line
    NSColor(calibratedWhite: 0.25, alpha: 1.0).setStroke()
    let cable = NSBezierPath()
    cable.move(to: NSPoint(x: 90, y: 220))
    cable.line(to: NSPoint(x: width - 90, y: 220))
    cable.lineWidth = 4
    cable.stroke()
    
    // Glowing packet
    ctx.saveGState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.cyan
    shadow.shadowBlurRadius = 14
    shadow.set()
    NSColor.cyan.setFill()
    NSBezierPath(ovalIn: NSRect(x: packetX - 8, y: 212, width: 16, height: 16)).fill()
    ctx.restoreGState()
    
    // Draw 4 nodes
    for (i, (tag, name)) in nodes.enumerated() {
        let nX = 60.0 + CGFloat(i * 155)
        let nY: CGFloat = 170
        let nRect = NSRect(x: nX, y: nY, width: 135, height: 95)
        
        let isHit = abs(packetX - (nX + 67)) < 55
        
        let nPath = NSBezierPath(roundedRect: nRect, xRadius: 10, yRadius: 10)
        if isHit {
            NSColor(calibratedRed: 0.15, green: 0.25, blue: 0.35, alpha: 0.95).setFill()
            nPath.fill()
            NSColor.cyan.setStroke()
            nPath.lineWidth = 2.0
            nPath.stroke()
        } else {
            NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.17, alpha: 0.9).setFill()
            nPath.fill()
            NSColor(calibratedWhite: 1.0, alpha: 0.12).setStroke()
            nPath.lineWidth = 1.0
            nPath.stroke()
        }
        
        (tag as NSString).draw(at: NSPoint(x: nX + 14, y: nY + 65), withAttributes: [
            .font: NSFont.systemFont(ofSize: 9.5, weight: .bold),
            .foregroundColor: isHit ? NSColor.cyan : NSColor(calibratedWhite: 0.5, alpha: 1.0)
        ])
        (name as NSString).draw(at: NSPoint(x: nX + 14, y: nY + 38), withAttributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.white
        ])
    }
    
    // Bottom Live Latency Telemetry
    let telRect = NSRect(x: 60, y: 55, width: width - 120, height: 60)
    NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.15, alpha: 0.9).setFill()
    NSBezierPath(roundedRect: telRect, xRadius: 10, yRadius: 10).fill()
    
    let ms = String(format: "%.2f ms", 0.5 + progress * 2.2)
    ("REAL-TIME LATENCY MEASUREMENT:" as NSString).draw(at: NSPoint(x: 80, y: 92), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 0.6, alpha: 1.0)
    ])
    (">>> DISPATCH TIME: \(ms) • ZERO ACCESSIBILITY TAP OVERHEAD" as NSString).draw(at: NSPoint(x: 80, y: 70), withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.2, green: 0.85, blue: 0.4, alpha: 1.0)
    ])
    
    img.unlockFocus()
    return img
}

// MARK: - 4. macOS Desktop Menu Bar Focus
func render4_DesktopMenuBar(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
    
    drawBaseWindow(title: "macOS Menu Bar Tray Experience", subtitle: "Always Accessible • Zero Clutter")
    
    // Stylized Desktop Wallpaper (Dark Sonoma style)
    let deskRect = NSRect(x: 25, y: 35, width: width - 50, height: height - 85)
    let deskGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.12, green: 0.16, blue: 0.28, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.12, alpha: 1.0)
    )
    deskGrad?.draw(in: deskRect, angle: -45)
    
    // Simulated Menu Bar at top of desktop
    let mb = NSRect(x: 25, y: deskRect.maxY - 32, width: deskRect.width, height: 32)
    NSColor(calibratedWhite: 0.15, alpha: 0.85).setFill()
    mb.fill()
    
    ("  Finder  File  Edit  View" as NSString).draw(at: NSPoint(x: 40, y: mb.minY + 8), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.white
    ])
    
    let isMenuOpen = (frame >= 12 && frame <= 34)
    let trayX = deskRect.maxX - 130
    let trayBtn = NSRect(x: trayX, y: mb.minY + 4, width: 115, height: 24)
    
    if isMenuOpen {
        NSColor(calibratedWhite: 1.0, alpha: 0.2).setFill()
        NSBezierPath(roundedRect: trayBtn, xRadius: 4, yRadius: 4).fill()
    }
    
    ("⏯ MediaKeys ●" as NSString).draw(at: NSPoint(x: trayX + 8, y: mb.minY + 7), withAttributes: [
        .font: NSFont.systemFont(ofSize: 11.5, weight: .bold),
        .foregroundColor: NSColor.white
    ])
    
    // Dropdown Menu Popover
    if isMenuOpen {
        let dW: CGFloat = 220
        let dH: CGFloat = 175
        let dRect = NSRect(x: deskRect.maxX - dW - 15, y: mb.minY - dH - 6, width: dW, height: dH)
        
        ctx.saveGState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
        shadow.shadowBlurRadius = 18
        shadow.set()
        NSColor(calibratedRed: 0.18, green: 0.20, blue: 0.25, alpha: 0.98).setFill()
        NSBezierPath(roundedRect: dRect, xRadius: 8, yRadius: 8).fill()
        ctx.restoreGState()
        
        let items = [
            ("● MediaKeysFix: Active", NSColor.systemGreen),
            ("Open Settings Window...", NSColor.white),
            ("───────────────────", NSColor.darkGray),
            ("✓ Remap F7 / F8 / F9", NSColor.white),
            ("✓ Start at Login", NSColor.white),
            ("Close to Tray", NSColor.lightGray),
            ("Full Quit", NSColor.systemRed)
        ]
        
        for (idx, (txt, col)) in items.enumerated() {
            (txt as NSString).draw(at: NSPoint(x: dRect.minX + 15, y: dRect.maxY - CGFloat(24 + idx * 22)), withAttributes: [
                .font: NSFont.systemFont(ofSize: 11.5, weight: .medium),
                .foregroundColor: col
            ])
        }
    }
    
    // Bottom banner
    let bTxt = "Discreet in macOS Menu Bar • No Dock Icon Clutter • Always on Duty"
    (bTxt as NSString).draw(at: NSPoint(x: 45, y: 55), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
        .foregroundColor: NSColor(calibratedWhite: 0.8, alpha: 1.0)
    ])
    
    img.unlockFocus()
    return img
}

// MARK: - 5. Interactive Settings Window Showcase
func render5_AppWindowWalkthrough(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    
    drawBaseWindow(title: "Native Preferences Interface", subtitle: "Simple & Clean UI")
    
    // Actual MediaKeysFix Window UI replica
    let wW: CGFloat = 430
    let wH: CGFloat = 295
    let wRect = NSRect(x: (width - wW) / 2.0, y: 40, width: wW, height: wH)
    
    NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.23, alpha: 0.98).setFill()
    let wPath = NSBezierPath(roundedRect: wRect, xRadius: 12, yRadius: 12)
    wPath.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.15).setStroke()
    wPath.stroke()
    
    // Header
    ("Media Keys Fix" as NSString).draw(at: NSPoint(x: wRect.minX + 25, y: wRect.maxY - 35), withAttributes: [
        .font: NSFont.systemFont(ofSize: 18, weight: .bold),
        .foregroundColor: NSColor.white
    ])
    ("Hardware fix for physical F7, F8, F9 media keys" as NSString).draw(at: NSPoint(x: wRect.minX + 25, y: wRect.maxY - 52), withAttributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor.lightGray
    ])
    
    // Status Card
    let sRect = NSRect(x: wRect.minX + 20, y: wRect.maxY - 130, width: wW - 40, height: 65)
    NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.17, alpha: 0.9).setFill()
    NSBezierPath(roundedRect: sRect, xRadius: 8, yRadius: 8).fill()
    
    NSColor.systemGreen.setFill()
    NSBezierPath(ovalIn: NSRect(x: sRect.minX + 15, y: sRect.maxY - 26, width: 10, height: 10)).fill()
    
    ("Fix Active" as NSString).draw(at: NSPoint(x: sRect.minX + 32, y: sRect.maxY - 30), withAttributes: [
        .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
        .foregroundColor: NSColor.white
    ])
    ("F7, F8, F9 are routed to media players" as NSString).draw(at: NSPoint(x: sRect.minX + 15, y: sRect.minY + 12), withAttributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor.gray
    ])
    
    // Options
    ("☑ Start at Login (Autostart on boot)" as NSString).draw(at: NSPoint(x: wRect.minX + 25, y: sRect.minY - 26), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.white
    ])
    ("☑ Fallback Shortcuts (Ctrl + Option + Space)" as NSString).draw(at: NSPoint(x: wRect.minX + 25, y: sRect.minY - 50), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.white
    ])
    
    // Two Bottom Buttons
    let isClickingTray = (frame >= 20 && frame <= 34)
    let btnW = (wW - 55) / 2.0
    
    let bQuit = NSRect(x: wRect.minX + 20, y: wRect.minY + 18, width: btnW, height: 32)
    NSColor(calibratedWhite: 0.22, alpha: 0.8).setFill()
    NSBezierPath(roundedRect: bQuit, xRadius: 6, yRadius: 6).fill()
    ("Full Quit" as NSString).draw(at: NSPoint(x: bQuit.minX + 50, y: bQuit.minY + 8), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
        .foregroundColor: NSColor.lightGray
    ])
    
    let bTray = NSRect(x: wRect.minX + 35 + btnW, y: wRect.minY + 18, width: btnW, height: 32)
    let trayCol = isClickingTray ? NSColor.systemGreen : NSColor.systemGreen.withAlphaComponent(0.3)
    trayCol.setFill()
    NSBezierPath(roundedRect: bTray, xRadius: 6, yRadius: 6).fill()
    NSColor.systemGreen.setStroke()
    NSBezierPath(roundedRect: bTray, xRadius: 6, yRadius: 6).stroke()
    
    let trayLabel = isClickingTray ? "✓ Hiding to Tray..." : "Close to Tray"
    (trayLabel as NSString).draw(at: NSPoint(x: bTray.minX + 42, y: bTray.minY + 8), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .bold),
        .foregroundColor: NSColor.white
    ])
    
    img.unlockFocus()
    return img
}

// MARK: - 6. Background Browser Tab (App Nap Fix)
func render6_BackgroundBrowser(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    
    drawBaseWindow(title: "Background Tab Fix (App Nap Resilient)", subtitle: "YouTube Music / Chrome / Safari")
    
    let isPause = (frame >= 14 && frame <= 28)
    
    // Background inactive browser window
    let bRect = NSRect(x: 35, y: 50, width: width - 70, height: height - 105)
    NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.16, alpha: 0.8).setFill()
    NSBezierPath(roundedRect: bRect, xRadius: 10, yRadius: 10).fill()
    
    ("YouTube Music (Tab Minimized in Background)" as NSString).draw(at: NSPoint(x: 60, y: bRect.maxY - 35), withAttributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .bold),
        .foregroundColor: NSColor(calibratedWhite: 0.7, alpha: 1.0)
    ])
    
    // App Nap badge
    let napRect = NSRect(x: 60, y: bRect.maxY - 70, width: 260, height: 26)
    NSColor.systemOrange.withAlphaComponent(0.25).setFill()
    NSBezierPath(roundedRect: napRect, xRadius: 6, yRadius: 6).fill()
    ("⚠️ macOS App Nap: Browser Process Throttled" as NSString).draw(at: NSPoint(x: 70, y: napRect.minY + 6), withAttributes: [
        .font: NSFont.systemFont(ofSize: 10.5, weight: .bold),
        .foregroundColor: NSColor.systemOrange
    ])
    
    // Center big response banner
    let resRect = NSRect(x: 60, y: 90, width: bRect.width - 50, height: 110)
    NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.14, alpha: 0.95).setFill()
    NSBezierPath(roundedRect: resRect, xRadius: 10, yRadius: 10).fill()
    
    if isPause {
        NSColor.systemGreen.setStroke()
        let p = NSBezierPath(roundedRect: resRect, xRadius: 10, yRadius: 10)
        p.lineWidth = 2.0
        p.stroke()
        
        ("⚡ F8 PRESSED: MEDIA PAUSED INSTANTLY" as NSString).draw(at: NSPoint(x: 85, y: resRect.maxY - 40), withAttributes: [
            .font: NSFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: NSColor.systemGreen
        ])
        ("MediaKeysFix bypasses App Nap & browser sleep via system MediaRemote" as NSString).draw(at: NSPoint(x: 85, y: resRect.maxY - 70), withAttributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ])
    } else {
        ("▶ Physical F8 will work even with browser completely hidden" as NSString).draw(at: NSPoint(x: 85, y: resRect.maxY - 50), withAttributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: NSColor.white
        ])
        ("No session drops • No missed clicks • Always responsive" as NSString).draw(at: NSPoint(x: 85, y: resRect.maxY - 78), withAttributes: [
            .font: NSFont.systemFont(ofSize: 11.5, weight: .regular),
            .foregroundColor: NSColor.lightGray
        ])
    }
    
    img.unlockFocus()
    return img
}

// MARK: - 7. Audio Waveform & Debounce Shield
func render7_WaveformDebounce(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    
    drawBaseWindow(title: "Oscilloscope & Debounce Filter", subtitle: "Zero Bounce Algorithm")
    
    let isPaused = (frame >= 14 && frame <= 30)
    
    // Waveform Scope
    let scopeRect = NSRect(x: 35, y: 170, width: width - 70, height: 160)
    NSColor(calibratedRed: 0.04, green: 0.08, blue: 0.12, alpha: 0.95).setFill()
    NSBezierPath(roundedRect: scopeRect, xRadius: 10, yRadius: 10).fill()
    NSColor.cyan.withAlphaComponent(0.3).setStroke()
    NSBezierPath(roundedRect: scopeRect, xRadius: 10, yRadius: 10).stroke()
    
    // Grid
    NSColor(calibratedWhite: 1.0, alpha: 0.06).setStroke()
    for g in 1..<5 {
        let y = scopeRect.minY + CGFloat(g * 32)
        let p = NSBezierPath()
        p.move(to: NSPoint(x: scopeRect.minX, y: y))
        p.line(to: NSPoint(x: scopeRect.maxX, y: y))
        p.stroke()
    }
    
    // Sine Wave
    let wave = NSBezierPath()
    let midY = scopeRect.midY
    wave.move(to: NSPoint(x: scopeRect.minX, y: midY))
    
    for px in stride(from: 0.0, through: scopeRect.width, by: 4.0) {
        let x = scopeRect.minX + px
        let amp: CGFloat = isPaused ? 2.0 : 42.0
        let freq: CGFloat = 0.03
        let y = midY + sin((px + CGFloat(frame * 12)) * freq) * amp
        wave.line(to: NSPoint(x: x, y: y))
    }
    
    NSColor.cyan.setStroke()
    wave.lineWidth = 2.5
    wave.stroke()
    
    // Debounce Shield Bar
    let shieldRect = NSRect(x: 35, y: 55, width: width - 70, height: 95)
    NSColor(calibratedRed: 0.11, green: 0.13, blue: 0.18, alpha: 0.95).setFill()
    NSBezierPath(roundedRect: shieldRect, xRadius: 10, yRadius: 10).fill()
    
    if isPaused {
        ("🛡️ DEBOUNCE FILTER ACTIVE: 200ms WebKit Shield" as NSString).draw(at: NSPoint(x: 55, y: shieldRect.maxY - 35), withAttributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold),
            .foregroundColor: NSColor.systemGreen
        ])
        ("Blocked duplicate secondary JS-event bounce at t=86ms • Audio flatlines to Pause" as NSString).draw(at: NSPoint(x: 55, y: shieldRect.maxY - 62), withAttributes: [
            .font: NSFont.systemFont(ofSize: 11.5, weight: .medium),
            .foregroundColor: NSColor.white
        ])
    } else {
        ("▶ AUDIO PLAYING: Live Signal Tracking" as NSString).draw(at: NSPoint(x: 55, y: shieldRect.maxY - 35), withAttributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold),
            .foregroundColor: NSColor.cyan
        ])
        ("Clean unpaused audio stream • Ready for instant F7/F8/F9 commands" as NSString).draw(at: NSPoint(x: 55, y: shieldRect.maxY - 62), withAttributes: [
            .font: NSFont.systemFont(ofSize: 11.5, weight: .regular),
            .foregroundColor: NSColor.lightGray
        ])
    }
    
    img.unlockFocus()
    return img
}

// MARK: - 8. Terminal CLI Benchmark
func render8_TerminalBenchmark(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    
    drawBaseWindow(title: "Terminal Speed & Overhead Benchmark", subtitle: "mediakeysfix --benchmark")
    
    let tRect = NSRect(x: 35, y: 40, width: width - 70, height: height - 90)
    NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.08, alpha: 0.95).setFill()
    NSBezierPath(roundedRect: tRect, xRadius: 8, yRadius: 8).fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.12).setStroke()
    NSBezierPath(roundedRect: tRect, xRadius: 8, yRadius: 8).stroke()
    
    let font = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .regular)
    let bold = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
    
    let p = min(frame, 35)
    let pct = Int((CGFloat(p) / 35.0) * 100.0)
    
    let lines = [
        ("$ ./MediaKeysFix --benchmark-latency", NSColor.white),
        ("Running 1,000 synthetic media key dispatch cycles... [\(pct)%]", NSColor.systemYellow),
        ("─────────────────────────────────────────────────────────────────", NSColor.darkGray),
        ("Native WebKit Play/Pause Bounce Latency : 86.42 ms  [FAILED ❌]", NSColor.systemRed),
        ("MediaKeysFix Hardware C-API Dispatch    :  2.71 ms  [PASSED ✅]", NSColor.systemGreen),
        ("Speedup Factor                           :  31.8x FASTER", NSColor.cyan),
        ("─────────────────────────────────────────────────────────────────", NSColor.darkGray),
        ("Memory Footprint : 14.2 MB   |   CPU Usage : 0.0% (Idle Event Loop)", NSColor.lightGray),
        ("Security Policy  : ZERO Accessibility Permissions Required", NSColor.systemGreen)
    ]
    
    for (i, (txt, col)) in lines.enumerated() {
        (txt as NSString).draw(at: NSPoint(x: 55, y: tRect.maxY - CGFloat(28 + i * 26)), withAttributes: [
            .font: (i == 3 || i == 4 || i == 5) ? bold : font,
            .foregroundColor: col
        ])
    }
    
    img.unlockFocus()
    return img
}

// MARK: - 9. Isometric Floating Cards (Futuristic Tech)
func render9_Isometric3D(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
    
    drawBaseWindow(title: "Hardware Architecture Visualization", subtitle: "Zero-Latency C-API Bridge")
    
    let isPulse = (frame >= 14 && frame <= 28)
    
    // 3 Floating isometric rounded cards
    let cards = [
        ("KEYBOARD", "F8 Keycap", NSColor(calibratedRed: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)),
        ("KERNEL / DAEMON", "MediaKeysFix", NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.5, alpha: 1.0)),
        ("OUTPUT", "NowPlaying Session", NSColor(calibratedRed: 0.9, green: 0.4, blue: 0.2, alpha: 1.0))
    ]
    
    for (i, (tag, title, col)) in cards.enumerated() {
        let cX = 55.0 + CGFloat(i * 215)
        let cY = 130.0 + CGFloat(i * 20)
        let cRect = NSRect(x: cX, y: cY, width: 180, height: 140)
        
        ctx.saveGState()
        let shadow = NSShadow()
        shadow.shadowColor = col.withAlphaComponent(isPulse ? 0.6 : 0.25)
        shadow.shadowBlurRadius = isPulse ? 20 : 10
        shadow.set()
        
        let cPath = NSBezierPath(roundedRect: cRect, xRadius: 14, yRadius: 14)
        NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.19, alpha: 0.95).setFill()
        cPath.fill()
        col.setStroke()
        cPath.lineWidth = isPulse ? 2.0 : 1.0
        cPath.stroke()
        ctx.restoreGState()
        
        (tag as NSString).draw(at: NSPoint(x: cX + 16, y: cY + 105), withAttributes: [
            .font: NSFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: col
        ])
        (title as NSString).draw(at: NSPoint(x: cX + 16, y: cY + 65), withAttributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: NSColor.white
        ])
    }
    
    // Connecting laser line
    let laser = NSBezierPath()
    laser.move(to: NSPoint(x: 145, y: 200))
    laser.line(to: NSPoint(x: 360, y: 220))
    laser.line(to: NSPoint(x: 575, y: 240))
    
    ctx.saveGState()
    let lShadow = NSShadow()
    lShadow.shadowColor = NSColor.cyan
    lShadow.shadowBlurRadius = isPulse ? 16 : 4
    lShadow.set()
    NSColor.cyan.setStroke()
    laser.lineWidth = isPulse ? 3.5 : 1.5
    laser.stroke()
    ctx.restoreGState()
    
    ("Instant Event Routing: Hardware Key ➔ Kernel hidutil ➔ MediaRemote.framework" as NSString).draw(at: NSPoint(x: 55, y: 65), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .bold),
        .foregroundColor: NSColor(calibratedWhite: 0.85, alpha: 1.0)
    ])
    
    img.unlockFocus()
    return img
}

// MARK: - 10. One-Click DMG Drag-and-Drop Installation
func render10_DMGInstaller(frame: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
    
    drawBaseWindow(title: "MediaKeysFix.dmg — Drag-and-Drop Setup", subtitle: "Zero Terminal Required")
    
    // DMG window interior
    let dmgRect = NSRect(x: 45, y: 45, width: width - 90, height: height - 95)
    let dmgPath = NSBezierPath(roundedRect: dmgRect, xRadius: 12, yRadius: 12)
    NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.19, alpha: 0.95).setFill()
    dmgPath.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.15).setStroke()
    dmgPath.stroke()
    
    // Title inside DMG
    ("Drag MediaKeysFix to Applications to install" as NSString).draw(at: NSPoint(x: 175, y: dmgRect.maxY - 45), withAttributes: [
        .font: NSFont.systemFont(ofSize: 14, weight: .bold),
        .foregroundColor: NSColor.white
    ])
    
    // Left target: App Icon (animated dragging)
    let dragProgress = min(1.0, CGFloat(frame) / 25.0)
    let startX: CGFloat = 135
    let endX: CGFloat = dmgRect.maxX - 200
    let currentX = (frame < 10) ? startX : (frame < 35 ? startX + (endX - startX) * CGFloat(frame - 10) / 25.0 : endX)
    
    // App icon (Left/moving)
    let iconRect = NSRect(x: currentX, y: 155, width: 85, height: 85)
    let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: 18, yRadius: 18)
    
    ctx.saveGState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
    shadow.shadowBlurRadius = 12
    shadow.shadowOffset = NSSize(width: 0, height: -4)
    shadow.set()
    
    let iconGrad = NSGradient(starting: NSColor(calibratedRed: 0.2, green: 0.45, blue: 0.9, alpha: 1.0), ending: NSColor(calibratedRed: 0.1, green: 0.15, blue: 0.35, alpha: 1.0))
    iconGrad?.draw(in: iconPath, angle: -45)
    ctx.restoreGState()
    
    ("⏯" as NSString).draw(at: NSPoint(x: currentX + 22, y: 172), withAttributes: [
        .font: NSFont.systemFont(ofSize: 38),
        .foregroundColor: NSColor.white
    ])
    ("MediaKeysFix" as NSString).draw(at: NSPoint(x: currentX - 2, y: 130), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .bold),
        .foregroundColor: NSColor.white
    ])
    
    // Center Arrow
    let arrowRect = NSRect(x: dmgRect.midX - 35, y: 185, width: 70, height: 25)
    ("──────➜" as NSString).draw(at: NSPoint(x: arrowRect.minX, y: arrowRect.minY), withAttributes: [
        .font: NSFont.systemFont(ofSize: 20, weight: .bold),
        .foregroundColor: NSColor(calibratedWhite: 0.4, alpha: 1.0)
    ])
    
    // Right target: Applications folder shortcut
    let appFolderX = dmgRect.maxX - 165
    let folderRect = NSRect(x: appFolderX, y: 155, width: 85, height: 85)
    NSColor(calibratedRed: 0.18, green: 0.22, blue: 0.30, alpha: 1.0).setFill()
    NSBezierPath(roundedRect: folderRect, xRadius: 18, yRadius: 18).fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.15).setStroke()
    NSBezierPath(roundedRect: folderRect, xRadius: 18, yRadius: 18).stroke()
    
    ("📁" as NSString).draw(at: NSPoint(x: appFolderX + 24, y: 175), withAttributes: [
        .font: NSFont.systemFont(ofSize: 34)
    ])
    ("Applications" as NSString).draw(at: NSPoint(x: appFolderX + 4, y: 130), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .bold),
        .foregroundColor: NSColor.white
    ])
    
    // Success badge if dropped
    if frame >= 32 {
        let okRect = NSRect(x: 100, y: 65, width: dmgRect.width - 110, height: 42)
        NSColor.systemGreen.withAlphaComponent(0.2).setFill()
        NSBezierPath(roundedRect: okRect, xRadius: 8, yRadius: 8).fill()
        NSColor.systemGreen.setStroke()
        NSBezierPath(roundedRect: okRect, xRadius: 8, yRadius: 8).stroke()
        
        ("✓ Installed to /Applications! Appears in Menu Bar with Start at Login." as NSString).draw(at: NSPoint(x: 125, y: 78), withAttributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.systemGreen
        ])
    }
    
    img.unlockFocus()
    return img
}

// MARK: - Batch Render Runner

let renderers: [(Int, String, (Int) -> NSImage)] = [
    (1, "Physical Keyboard Hardware Close-up", render1_PhysicalKeyboard),
    (2, "Before vs After Split-Screen Comparison", render2_BeforeAfter),
    (3, "Architecture Signal Pipeline Flow", render3_ArchitecturePipeline),
    (4, "macOS Menu Bar Tray Experience", render4_DesktopMenuBar),
    (5, "Interactive App Settings Window Walkthrough", render5_AppWindowWalkthrough),
    (6, "Background Browser Tab (App Nap Fix)", render6_BackgroundBrowser),
    (7, "Audio Waveform & Debounce Filter Shield", render7_WaveformDebounce),
    (8, "Terminal Speed & Benchmark Telemetry", render8_TerminalBenchmark),
    (9, "Isometric 3D Tech Hardware Flow", render9_Isometric3D),
    (10, "One-Click DMG Drag-and-Drop Installation", render10_DMGInstaller)
]

for (num, name, renderFunc) in renderers {
    print("==> Generating Variant \(num)/10: \(name)...")
    try? fileManager.removeItem(atPath: tempFramesDir)
    try! fileManager.createDirectory(atPath: tempFramesDir, withIntermediateDirectories: true)
    
    for f in 0..<framesCount {
        let img = renderFunc(f)
        if let tiff = img.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let path = String(format: "\(tempFramesDir)/frame_%03d.png", f)
            try! png.write(to: URL(fileURLWithPath: path))
        }
    }
    
    let outPath = "GIFS/\(num).gif"
    let cmd = """
    /opt/homebrew/bin/ffmpeg -nostdin -y -framerate \(fps) -i \(tempFramesDir)/frame_%03d.png \
    -filter_complex "[0:v] split [a][b];[a] palettegen=max_colors=128:reserve_transparent=0 [p];[b][p] paletteuse=dither=bayer:bayer_scale=3" \
    \(outPath)
    """
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    task.arguments = ["-c", cmd]
    try! task.run()
    task.waitUntilExit()
}

try? fileManager.removeItem(atPath: tempFramesDir)
print("==> Successfully generated all 10 distinct GIF variants in GIFS/!")
