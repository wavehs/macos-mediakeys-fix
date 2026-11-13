import Cocoa

let width: CGFloat = 720
let height: CGFloat = 400
let totalFrames = 105
let fps = 15

let fileManager = FileManager.default
let framesDir = "build/gif_frames"
try? fileManager.removeItem(atPath: framesDir)
try! fileManager.createDirectory(atPath: framesDir, withIntermediateDirectories: true)

func drawFrame(index: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }
    
    // Background
    let bgRect = NSRect(x: 0, y: 0, width: width, height: height)
    let bgGradient = NSGradient(
        starting: NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.13, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.07, alpha: 1.0)
    )
    bgGradient?.draw(in: bgRect, angle: -45)
    
    // Outer subtle border
    NSColor(calibratedWhite: 1.0, alpha: 0.08).setStroke()
    let borderPath = NSBezierPath(rect: bgRect.insetBy(dx: 0.5, dy: 0.5))
    borderPath.lineWidth = 1
    borderPath.stroke()
    
    // 1. macOS Top Menu Bar (height 36px, y: 364..400)
    let menuBarRect = NSRect(x: 0, y: height - 34, width: width, height: 34)
    NSColor(calibratedWhite: 0.12, alpha: 0.85).setFill()
    menuBarRect.fill()
    
    NSColor(calibratedWhite: 1.0, alpha: 0.08).setStroke()
    let menuDiv = NSBezierPath()
    menuDiv.move(to: NSPoint(x: 0, y: height - 34))
    menuDiv.line(to: NSPoint(x: width, y: height - 34))
    menuDiv.stroke()
    
    // Traffic lights (simulated window control)
    let dotColors: [NSColor] = [
        NSColor(calibratedRed: 1.0, green: 0.36, blue: 0.33, alpha: 1.0),
        NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.18, alpha: 1.0),
        NSColor(calibratedRed: 0.16, green: 0.80, blue: 0.38, alpha: 1.0)
    ]
    for (i, col) in dotColors.enumerated() {
        let dotRect = NSRect(x: 18 + CGFloat(i * 18), y: height - 22, width: 10, height: 10)
        col.setFill()
        NSBezierPath(ovalIn: dotRect).fill()
    }
    
    // Menu Bar Left text: "Safari - YouTube Music"
    let menuFont = NSFont.systemFont(ofSize: 11.5, weight: .medium)
    let menuAttrs: [NSAttributedString.Key: Any] = [
        .font: menuFont,
        .foregroundColor: NSColor(calibratedWhite: 0.8, alpha: 0.9)
    ]
    ("YouTube Music" as NSString).draw(at: NSPoint(x: 85, y: height - 24), withAttributes: menuAttrs)
    
    // Menu Bar Right: Tray icon "MediaKeysFix"
    let isMenuOpen = (index >= 75 && index <= 100)
    let trayX: CGFloat = width - 120
    let trayRect = NSRect(x: trayX - 6, y: height - 30, width: 105, height: 26)
    
    if isMenuOpen {
        NSColor(calibratedWhite: 1.0, alpha: 0.2).setFill()
        NSBezierPath(roundedRect: trayRect, xRadius: 4, yRadius: 4).fill()
    }
    
    // Tray text/icon
    let trayFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
    let trayAttrs: [NSAttributedString.Key: Any] = [
        .font: trayFont,
        .foregroundColor: isMenuOpen ? NSColor.white : NSColor(calibratedWhite: 0.9, alpha: 1.0)
    ]
    ("⏯ MediaKeys" as NSString).draw(at: NSPoint(x: trayX + 4, y: height - 23), withAttributes: trayAttrs)
    
    // Active green dot in tray
    NSColor(calibratedRed: 0.2, green: 0.85, blue: 0.4, alpha: 1.0).setFill()
    NSBezierPath(ovalIn: NSRect(x: trayX + 88, y: height - 20, width: 6, height: 6)).fill()
    
    // Animation timeline parameters:
    // Frame 0..25: Playing track 1 ("Starboy")
    // Frame 26..50: Press F8 -> Paused
    // Frame 51..74: Press F9 -> Next Track ("Blinding Lights"), Playing
    // Frame 75..104: Click Tray Menu -> Dropdown appears
    
    var isPlaying = true
    var trackName = "Starboy"
    var artistName = "The Weeknd • Starboy"
    var activeKey: Int = 0 // 7, 8, 9
    var keyGlowAmount: CGFloat = 0.0
    var statusBadgeText = "Status: Active • Intercepting F7, F8, F9"
    var statusBadgeColor = NSColor(calibratedRed: 0.16, green: 0.80, blue: 0.38, alpha: 1.0)
    
    if index >= 26 && index < 51 {
        // F8 pressed, track paused
        activeKey = 8
        let local = CGFloat(index - 26) / 25.0
        keyGlowAmount = sin(local * .pi)
        isPlaying = false
        statusBadgeText = "⚡ F8 Pressed: Instant Pause (2.7ms) • WebKit Bounce Fixed!"
        statusBadgeColor = NSColor(calibratedRed: 0.25, green: 0.70, blue: 1.0, alpha: 1.0)
    } else if index >= 51 && index < 75 {
        // F9 pressed, next track
        activeKey = 9
        let local = CGFloat(index - 51) / 24.0
        keyGlowAmount = sin(local * .pi)
        trackName = "Blinding Lights"
        artistName = "The Weeknd • After Hours"
        isPlaying = true
        statusBadgeText = "⚡ F9 Pressed: Skipped to Next Track instantly"
        statusBadgeColor = NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.55, alpha: 1.0)
    } else if index >= 75 {
        trackName = "Blinding Lights"
        artistName = "The Weeknd • After Hours"
        isPlaying = true
        statusBadgeText = "Menu Bar: Start at Login is Active"
        statusBadgeColor = NSColor(calibratedRed: 0.7, green: 0.5, blue: 1.0, alpha: 1.0)
    }
    
    // 2. Left Side: Now Playing Player Card (y: 60..320, width: 310)
    let playerRect = NSRect(x: 32, y: 65, width: 310, height: 260)
    let playerBox = NSBezierPath(roundedRect: playerRect, xRadius: 14, yRadius: 14)
    NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.21, alpha: 0.9).setFill()
    playerBox.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.1).setStroke()
    playerBox.lineWidth = 1
    playerBox.stroke()
    
    // Album Art (100x100)
    let artRect = NSRect(x: 48, y: 195, width: 90, height: 90)
    let artPath = NSBezierPath(roundedRect: artRect, xRadius: 10, yRadius: 10)
    let artGradient = NSGradient(
        starting: (trackName == "Starboy") ? NSColor(calibratedRed: 0.85, green: 0.15, blue: 0.35, alpha: 1.0) : NSColor(calibratedRed: 0.95, green: 0.45, blue: 0.15, alpha: 1.0),
        ending: (trackName == "Starboy") ? NSColor(calibratedRed: 0.25, green: 0.05, blue: 0.55, alpha: 1.0) : NSColor(calibratedRed: 0.55, green: 0.05, blue: 0.25, alpha: 1.0)
    )
    artGradient?.draw(in: artPath, angle: 45)
    
    // Vinyl / Music icon inside art
    let musicIcon = (trackName == "Starboy") ? "⚡" : "🔥"
    let musicFont = NSFont.systemFont(ofSize: 34)
    (musicIcon as NSString).draw(at: NSPoint(x: 75, y: 220), withAttributes: [.font: musicFont])
    
    // Player titles
    let titleFont = NSFont.systemFont(ofSize: 16, weight: .bold)
    (trackName as NSString).draw(at: NSPoint(x: 152, y: 250), withAttributes: [
        .font: titleFont,
        .foregroundColor: NSColor.white
    ])
    
    let artistFont = NSFont.systemFont(ofSize: 12, weight: .regular)
    (artistName as NSString).draw(at: NSPoint(x: 152, y: 230), withAttributes: [
        .font: artistFont,
        .foregroundColor: NSColor(calibratedWhite: 0.65, alpha: 1.0)
    ])
    
    // State pill: "PLAYING" vs "PAUSED"
    let stateRect = NSRect(x: 152, y: 202, width: 78, height: 20)
    let statePath = NSBezierPath(roundedRect: stateRect, xRadius: 5, yRadius: 5)
    if isPlaying {
        NSColor(calibratedRed: 0.16, green: 0.75, blue: 0.35, alpha: 0.25).setFill()
    } else {
        NSColor(calibratedRed: 1.0, green: 0.65, blue: 0.15, alpha: 0.25).setFill()
    }
    statePath.fill()
    
    let stateText = isPlaying ? "● PLAYING" : "❚❚ PAUSED"
    let stateColor = isPlaying ? NSColor(calibratedRed: 0.25, green: 0.9, blue: 0.45, alpha: 1.0) : NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.25, alpha: 1.0)
    (stateText as NSString).draw(at: NSPoint(x: 158, y: 205), withAttributes: [
        .font: NSFont.systemFont(ofSize: 9.5, weight: .bold),
        .foregroundColor: stateColor
    ])
    
    // Progress Bar
    let barBg = NSRect(x: 48, y: 155, width: 275, height: 5)
    NSColor(calibratedWhite: 0.25, alpha: 1.0).setFill()
    NSBezierPath(roundedRect: barBg, xRadius: 2.5, yRadius: 2.5).fill()
    
    let progressFactor: CGFloat = (trackName == "Starboy") ? CGFloat((index * 2) % 100) / 100.0 : CGFloat(20 + ((index * 2) % 80)) / 100.0
    let progW = max(10, 275 * progressFactor)
    let barProg = NSRect(x: 48, y: 155, width: progW, height: 5)
    NSColor(calibratedRed: 0.3, green: 0.7, blue: 1.0, alpha: 1.0).setFill()
    NSBezierPath(roundedRect: barProg, xRadius: 2.5, yRadius: 2.5).fill()
    
    // Playback time
    let timeFont = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
    ("1:24" as NSString).draw(at: NSPoint(x: 48, y: 138), withAttributes: [.font: timeFont, .foregroundColor: NSColor(calibratedWhite: 0.5, alpha: 1.0)])
    ("3:50" as NSString).draw(at: NSPoint(x: 298, y: 138), withAttributes: [.font: timeFont, .foregroundColor: NSColor(calibratedWhite: 0.5, alpha: 1.0)])
    
    // Equalizer bars (bottom of card)
    for b in 0..<18 {
        let barH: CGFloat = isPlaying ? CGFloat(6 + ((index * 7 + b * 13) % 22)) : 4.0
        let eqX = 48 + CGFloat(b * 15)
        let eqRect = NSRect(x: eqX, y: 88, width: 8, height: barH)
        let eqCol = isPlaying ? NSColor(calibratedRed: 0.35, green: 0.65, blue: 1.0, alpha: 0.8) : NSColor(calibratedWhite: 0.3, alpha: 0.6)
        eqCol.setFill()
        NSBezierPath(roundedRect: eqRect, xRadius: 3, yRadius: 3).fill()
    }
    
    // 3. Right Side: Physical Keyboard Keys Simulation (x: 370..680, y: 150..325)
    let keyCardRect = NSRect(x: 368, y: 155, width: 320, height: 170)
    let keyCardBox = NSBezierPath(roundedRect: keyCardRect, xRadius: 14, yRadius: 14)
    NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.21, alpha: 0.9).setFill()
    keyCardBox.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.1).setStroke()
    keyCardBox.lineWidth = 1
    keyCardBox.stroke()
    
    let keyCardTitle = "Physical Mac Media Keys:"
    (keyCardTitle as NSString).draw(at: NSPoint(x: 386, y: 295), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
        .foregroundColor: NSColor(calibratedWhite: 0.75, alpha: 1.0)
    ])
    
    let keys: [(Int, String, String)] = [
        (7, "F7", "⏮ Prev"),
        (8, "F8", "⏯ Play"),
        (9, "F9", "⏭ Next")
    ]
    
    for (i, item) in keys.enumerated() {
        let (num, fLabel, actionLabel) = item
        let isThisKeyActive = (activeKey == num && keyGlowAmount > 0.05)
        let kX = 386 + CGFloat(i * 95)
        let kY = 195 - (isThisKeyActive ? 3.0 : 0.0) // Key press depth
        let kRect = NSRect(x: kX, y: kY, width: 85, height: 85)
        
        let keyPath = NSBezierPath(roundedRect: kRect, xRadius: 12, yRadius: 12)
        
        if isThisKeyActive {
            // Glowing pressed keycap
            ctx.saveGState()
            let shadow = NSShadow()
            shadow.shadowColor = (num == 8) ? NSColor(calibratedRed: 0.25, green: 0.7, blue: 1.0, alpha: 0.8) : NSColor(calibratedRed: 0.3, green: 0.9, blue: 0.5, alpha: 0.8)
            shadow.shadowOffset = .zero
            shadow.shadowBlurRadius = 16 * keyGlowAmount
            shadow.set()
            NSColor(calibratedRed: 0.22, green: 0.28, blue: 0.38, alpha: 1.0).setFill()
            keyPath.fill()
            ctx.restoreGState()
            
            NSColor(calibratedRed: 0.4, green: 0.8, blue: 1.0, alpha: 1.0).setStroke()
            keyPath.lineWidth = 2.0
            keyPath.stroke()
        } else {
            // Idle keycap
            NSColor(calibratedRed: 0.18, green: 0.20, blue: 0.27, alpha: 1.0).setFill()
            keyPath.fill()
            NSColor(calibratedWhite: 1.0, alpha: 0.12).setStroke()
            keyPath.lineWidth = 1.0
            keyPath.stroke()
        }
        
        // F-label (F7, F8, F9)
        let fFont = NSFont.monospacedSystemFont(ofSize: 15, weight: .bold)
        let fCol = isThisKeyActive ? NSColor.white : NSColor(calibratedWhite: 0.9, alpha: 1.0)
        (fLabel as NSString).draw(at: NSPoint(x: kX + 16, y: kY + 48), withAttributes: [.font: fFont, .foregroundColor: fCol])
        
        // Action symbol
        let aFont = NSFont.systemFont(ofSize: 11, weight: .medium)
        let aCol = isThisKeyActive ? NSColor(calibratedRed: 0.4, green: 0.8, blue: 1.0, alpha: 1.0) : NSColor(calibratedWhite: 0.55, alpha: 1.0)
        (actionLabel as NSString).draw(at: NSPoint(x: kX + 14, y: kY + 20), withAttributes: [.font: aFont, .foregroundColor: aCol])
    }
    
    // Status Badge at Bottom Right (y: 65..135)
    let badgeRect = NSRect(x: 368, y: 65, width: 320, height: 75)
    let badgeBox = NSBezierPath(roundedRect: badgeRect, xRadius: 12, yRadius: 12)
    NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.21, alpha: 0.9).setFill()
    badgeBox.fill()
    NSColor(calibratedWhite: 1.0, alpha: 0.1).setStroke()
    badgeBox.lineWidth = 1
    badgeBox.stroke()
    
    // Status text in badge
    ("⚡ MediaKeysFix Engine" as NSString).draw(at: NSPoint(x: 384, y: 110), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .bold),
        .foregroundColor: statusBadgeColor
    ])
    
    let subBadge = (activeKey == 8)
        ? "Bypassed WebKit 86ms bounce. Clean pause."
        : (activeKey == 9)
            ? "Track skipped directly via MediaRemote C-API."
            : "Kernel HID Remap + Carbon Global HotKeys."
    (subBadge as NSString).draw(at: NSPoint(x: 384, y: 88), withAttributes: [
        .font: NSFont.systemFont(ofSize: 10.5, weight: .regular),
        .foregroundColor: NSColor(calibratedWhite: 0.65, alpha: 1.0)
    ])
    
    let latencyBadge = "Zero Permissions • Response ~2.7ms"
    (latencyBadge as NSString).draw(at: NSPoint(x: 384, y: 72), withAttributes: [
        .font: NSFont.systemFont(ofSize: 9.5, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 0.45, alpha: 1.0)
    ])
    
    // 4. Dropdown Menu Simulation when Tray icon is clicked (index 75..100)
    if isMenuOpen {
        let dropW: CGFloat = 200
        let dropH: CGFloat = 145
        let dropRect = NSRect(x: width - dropW - 20, y: height - 34 - dropH, width: dropW, height: dropH)
        
        ctx.saveGState()
        let menuShadow = NSShadow()
        menuShadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
        menuShadow.shadowOffset = NSSize(width: 0, height: -6)
        menuShadow.shadowBlurRadius = 18
        menuShadow.set()
        
        let dropPath = NSBezierPath(roundedRect: dropRect, xRadius: 8, yRadius: 8)
        NSColor(calibratedRed: 0.18, green: 0.20, blue: 0.26, alpha: 0.98).setFill()
        dropPath.fill()
        ctx.restoreGState()
        
        NSColor(calibratedWhite: 1.0, alpha: 0.15).setStroke()
        dropPath.lineWidth = 1
        dropPath.stroke()
        
        let dropFont = NSFont.systemFont(ofSize: 11.5, weight: .medium)
        let items = [
            ("● MediaKeysFix: Active", NSColor(calibratedRed: 0.2, green: 0.85, blue: 0.4, alpha: 1.0)),
            ("✓ Remap F7 / F8 / F9", NSColor.white),
            ("✓ Start at Login", NSColor.white),
            ("✓ Fallback Hotkeys", NSColor.white),
            ("  Close to Tray / Full Quit", NSColor(calibratedWhite: 0.6, alpha: 1.0))
        ]
        
        for (idx, item) in items.enumerated() {
            let itemY = dropRect.maxY - CGFloat(24 + idx * 24)
            (item.0 as NSString).draw(at: NSPoint(x: dropRect.minX + 14, y: itemY), withAttributes: [
                .font: dropFont,
                .foregroundColor: item.1
            ])
        }
    }
    
    img.unlockFocus()
    return img
}

print("==> Rendering \(totalFrames) animation frames...")

for i in 0..<totalFrames {
    let frameImg = drawFrame(index: i)
    if let tiff = frameImg.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let filename = String(format: "\(framesDir)/frame_%03d.png", i)
        try! png.write(to: URL(fileURLWithPath: filename))
    }
}

print("==> Encoding optimized GIF via ffmpeg...")
let ffmpegCmd = """
/opt/homebrew/bin/ffmpeg -nostdin -y -framerate \(fps) -i \(framesDir)/frame_%03d.png \
-filter_complex "[0:v] split [a][b];[a] palettegen=max_colors=128:reserve_transparent=0 [p];[b][p] paletteuse=dither=bayer:bayer_scale=3" \
resources/demo.gif
"""

let task = Process()
task.executableURL = URL(fileURLWithPath: "/bin/sh")
task.arguments = ["-c", ffmpegCmd]
try! task.run()
task.waitUntilExit()

try? fileManager.removeItem(atPath: framesDir)
print("==> demo.gif successfully created at resources/demo.gif!")
