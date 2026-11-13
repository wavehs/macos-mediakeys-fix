import AppKit
import Foundation

// MARK: - Global Configuration
let width: Int = 720
let height: Int = 400
let frameCount: Int = 48
let fps: Int = 12
let outputDir = "GIFS"
let tempFramesDir = "build/temp_song_frames"

let cover1Path = "GIFS/photos for songs/image.png"
let cover2Path = "GIFS/photos for songs/image copy.png"

guard let cover1 = NSImage(contentsOfFile: cover1Path),
      let cover2 = NSImage(contentsOfFile: cover2Path) else {
    print("Error: Could not load song covers from \(cover1Path) and \(cover2Path)")
    exit(1)
}

let song1Title = "After Hours"
let song1Artist = "The Weeknd"
let song2Title = "Starboy"
let song2Artist = "The Weeknd ft. Daft Punk"

let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
try? fm.createDirectory(atPath: tempFramesDir, withIntermediateDirectories: true)

// Timeline states across 48 frames:
// Frames 0...12: Song 1 Playing
// Frames 13...24: F8 Pressed -> Paused
// Frames 25...36: F9 Pressed -> Next Song (Song 2) Playing
// Frames 37...47: F7 Pressed -> Prev Song (Song 1) Playing

struct PlaybackState {
    let currentSong: Int // 1 or 2
    let title: String
    let artist: String
    let cover: NSImage
    let isPlaying: Bool
    let activeKey: String? // "F7", "F8", "F9" or nil
    let actionLabel: String
    let progress: CGFloat // 0.0 to 1.0
}

func getPlaybackState(frame: Int) -> PlaybackState {
    if frame <= 12 {
        let prog = CGFloat(frame) / 48.0 * 0.4 + 0.25
        return PlaybackState(
            currentSong: 1,
            title: song1Title,
            artist: song1Artist,
            cover: cover1,
            isPlaying: true,
            activeKey: nil,
            actionLabel: "Background Music Playing (YouTube Music)",
            progress: prog
        )
    } else if frame <= 24 {
        return PlaybackState(
            currentSong: 1,
            title: song1Title,
            artist: song1Artist,
            cover: cover1,
            isPlaying: false,
            activeKey: "F8",
            actionLabel: "F8 Pressed ➔ MediaKeysFix Instant Pause",
            progress: 0.35
        )
    } else if frame <= 36 {
        let sub = CGFloat(frame - 25) / 12.0
        return PlaybackState(
            currentSong: 2,
            title: song2Title,
            artist: song2Artist,
            cover: cover2,
            isPlaying: true,
            activeKey: "F9",
            actionLabel: "F9 Pressed ➔ Skip to Next Track",
            progress: sub * 0.2 + 0.05
        )
    } else {
        let sub = CGFloat(frame - 37) / 11.0
        return PlaybackState(
            currentSong: 1,
            title: song1Title,
            artist: song1Artist,
            cover: cover1,
            isPlaying: true,
            activeKey: "F7",
            actionLabel: "F7 Pressed ➔ Previous Track",
            progress: sub * 0.15 + 0.20
        )
    }
}

// MARK: - Drawing Utilities
extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xff) / 255.0
        let g = CGFloat((hex >> 8) & 0xff) / 255.0
        let b = CGFloat(hex & 0xff) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

func drawText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) {
    let p = NSMutableParagraphStyle()
    p.alignment = alignment
    p.lineBreakMode = .byTruncatingTail
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: p
    ]
    let s = NSAttributedString(string: text, attributes: attrs)
    s.draw(in: rect)
}

func drawCoverImage(_ image: NSImage, in rect: NSRect, radius: CGFloat = 12.0) {
    NSGraphicsContext.saveGraphicsState()
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.addClip()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    
    // Border
    NSColor(white: 1.0, alpha: 0.15).setStroke()
    let border = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    border.lineWidth = 1.0
    border.stroke()
}

func drawKeyCap(rect: NSRect, key: String, symbol: String, isPressed: Bool) {
    NSGraphicsContext.saveGraphicsState()
    
    let bgCol = isPressed ? NSColor(hex: 0x3b82f6) : NSColor(hex: 0x1f2430)
    let borderCol = isPressed ? NSColor(hex: 0x93c5fd) : NSColor(white: 1.0, alpha: 0.18)
    
    if isPressed {
        // Glow effect
        let glow = NSBezierPath(roundedRect: rect.insetBy(dx: -4, dy: -4), xRadius: 10, yRadius: 10)
        NSColor(hex: 0x3b82f6, alpha: 0.35).setFill()
        glow.fill()
    }
    
    let keyPath = NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7)
    bgCol.setFill()
    keyPath.fill()
    borderCol.setStroke()
    keyPath.lineWidth = isPressed ? 2.0 : 1.0
    keyPath.stroke()
    
    let textColor = isPressed ? NSColor.white : NSColor(white: 0.85, alpha: 1.0)
    let subColor = isPressed ? NSColor(white: 0.95, alpha: 1.0) : NSColor(hex: 0x94a3b8)
    
    let keyRect = NSRect(x: rect.minX, y: rect.midY - 1, width: rect.width, height: 16)
    drawText(key, in: keyRect, font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold), color: textColor, alignment: .center)
    
    let symRect = NSRect(x: rect.minX, y: rect.minY + 3, width: rect.width, height: 14)
    drawText(symbol, in: symRect, font: NSFont.systemFont(ofSize: 11, weight: .bold), color: subColor, alignment: .center)
    
    NSGraphicsContext.restoreGraphicsState()
}

func drawEqualizerBars(in rect: NSRect, isPlaying: Bool, frame: Int, color: NSColor) {
    let barCount = 18
    let barWidth = (rect.width - CGFloat(barCount - 1) * 3.0) / CGFloat(barCount)
    
    for i in 0..<barCount {
        let barX = rect.minX + CGFloat(i) * (barWidth + 3.0)
        let phase = Double(frame) * 0.6 + Double(i) * 0.8
        let hRatio: CGFloat
        if isPlaying {
            hRatio = CGFloat(0.2 + 0.8 * abs(sin(phase)))
        } else {
            hRatio = 0.08
        }
        let barH = max(4.0, rect.height * hRatio)
        let barRect = NSRect(x: barX, y: rect.midY - barH / 2.0, width: barWidth, height: barH)
        
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2.0, yRadius: barWidth / 2.0)
        color.setFill()
        barPath.fill()
    }
}

// MARK: - 10 Unique Variant Renderers

// VARIANT 1: MacBook Pro Keyboard Deck & Floating Glass Music Card
func renderVariant1(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Background: Dark aluminum deck
    let bgGrad = NSGradient(colors: [NSColor(hex: 0x0c0f17), NSColor(hex: 0x161b26)])!
    bgGrad.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
    
    // Top Banner
    let topBadgeRect = NSRect(x: 30, y: 350, width: 660, height: 32)
    let badgePath = NSBezierPath(roundedRect: topBadgeRect, xRadius: 8, yRadius: 8)
    NSColor(hex: 0x1e293b, alpha: 0.9).setFill()
    badgePath.fill()
    NSColor(white: 1.0, alpha: 0.1).setStroke()
    badgePath.stroke()
    
    drawText("⚡ MediaKeysFix in Action", in: NSRect(x: 45, y: 358, width: 220, height: 18), font: NSFont.systemFont(ofSize: 13, weight: .bold), color: NSColor(hex: 0x38bdf8))
    drawText(state.actionLabel, in: NSRect(x: 270, y: 358, width: 405, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .medium), color: NSColor.white, alignment: .right)
    
    // Center: Floating Music Player Card
    let cardRect = NSRect(x: 40, y: 150, width: 640, height: 180)
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 16, yRadius: 16)
    NSColor(hex: 0x111827, alpha: 0.95).setFill()
    cardPath.fill()
    NSColor(white: 1.0, alpha: 0.15).setStroke()
    cardPath.lineWidth = 1.5
    cardPath.stroke()
    
    // Album Art
    let coverRect = NSRect(x: 60, y: 165, width: 150, height: 150)
    drawCoverImage(state.cover, in: coverRect, radius: 12)
    
    // Track Details
    let detailsX: CGFloat = 230
    drawText(state.title, in: NSRect(x: detailsX, y: 275, width: 420, height: 26), font: NSFont.systemFont(ofSize: 20, weight: .heavy), color: NSColor.white)
    drawText(state.artist, in: NSRect(x: detailsX, y: 250, width: 420, height: 20), font: NSFont.systemFont(ofSize: 14, weight: .medium), color: NSColor(hex: 0x94a3b8))
    
    // Equalizer
    let eqRect = NSRect(x: detailsX, y: 215, width: 180, height: 24)
    drawEqualizerBars(in: eqRect, isPlaying: state.isPlaying, frame: frame, color: state.isPlaying ? NSColor(hex: 0x10b981) : NSColor(hex: 0x64748b))
    
    let statusText = state.isPlaying ? "PLAYING" : "PAUSED (Instant)"
    let statusColor = state.isPlaying ? NSColor(hex: 0x10b981) : NSColor(hex: 0xf59e0b)
    drawText(statusText, in: NSRect(x: detailsX + 200, y: 217, width: 220, height: 20), font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold), color: statusColor)
    
    // Progress Bar
    let barRect = NSRect(x: detailsX, y: 185, width: 420, height: 6)
    NSColor(white: 1.0, alpha: 0.1).setFill()
    NSBezierPath(roundedRect: barRect, xRadius: 3, yRadius: 3).fill()
    
    let fillW = max(10, barRect.width * state.progress)
    let fillRect = NSRect(x: barRect.minX, y: barRect.minY, width: fillW, height: 6)
    NSColor(hex: 0x38bdf8).setFill()
    NSBezierPath(roundedRect: fillRect, xRadius: 3, yRadius: 3).fill()
    
    // Bottom: Physical Keyboard Deck with Function Keys
    let deckRect = NSRect(x: 40, y: 25, width: 640, height: 105)
    let deckPath = NSBezierPath(roundedRect: deckRect, xRadius: 14, yRadius: 14)
    NSColor(hex: 0x090d16).setFill()
    deckPath.fill()
    NSColor(white: 1.0, alpha: 0.08).setStroke()
    deckPath.stroke()
    
    drawText("MacBook Pro Function Keys", in: NSRect(x: 60, y: 100, width: 300, height: 18), font: NSFont.systemFont(ofSize: 11, weight: .bold), color: NSColor(hex: 0x64748b))
    
    let keyW: CGFloat = 85
    let keyH: CGFloat = 60
    let keyY: CGFloat = 38
    let startX: CGFloat = 175
    
    drawKeyCap(rect: NSRect(x: startX, y: keyY, width: keyW, height: keyH), key: "F7", symbol: "⏮ Prev", isPressed: state.activeKey == "F7")
    drawKeyCap(rect: NSRect(x: startX + 110, y: keyY, width: keyW, height: keyH), key: "F8", symbol: state.isPlaying ? "❚❚ Pause" : "▶ Play", isPressed: state.activeKey == "F8")
    drawKeyCap(rect: NSRect(x: startX + 220, y: keyY, width: keyW, height: keyH), key: "F9", symbol: "⏭ Next", isPressed: state.activeKey == "F9")
}

// VARIANT 2: Split-Screen Comparison: "Without Fix (Bounce Bug)" vs "With MediaKeysFix"
func renderVariant2(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Dark base
    NSColor(hex: 0x0a0c10).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Left Half: Without MediaKeysFix (Red accent)
    let leftRect = NSRect(x: 20, y: 20, width: 330, height: 360)
    let leftPath = NSBezierPath(roundedRect: leftRect, xRadius: 12, yRadius: 12)
    NSColor(hex: 0x181014).setFill()
    leftPath.fill()
    NSColor(hex: 0xef4444, alpha: 0.4).setStroke()
    leftPath.lineWidth = 1.5
    leftPath.stroke()
    
    drawText("❌ WITHOUT FIX", in: NSRect(x: 35, y: 345, width: 300, height: 22), font: NSFont.systemFont(ofSize: 14, weight: .heavy), color: NSColor(hex: 0xf87171))
    drawText("Standard macOS WebKit Bounce Bug", in: NSRect(x: 35, y: 325, width: 300, height: 16), font: NSFont.systemFont(ofSize: 11, weight: .regular), color: NSColor(hex: 0xa1a1aa))
    
    // Left Album Cover (small)
    let leftCoverRect = NSRect(x: 35, y: 220, width: 90, height: 90)
    drawCoverImage(cover1, in: leftCoverRect, radius: 8)
    drawText(song1Title, in: NSRect(x: 135, y: 275, width: 200, height: 20), font: NSFont.systemFont(ofSize: 14, weight: .bold), color: NSColor.white)
    drawText(song1Artist, in: NSRect(x: 135, y: 255, width: 200, height: 16), font: NSFont.systemFont(ofSize: 11, weight: .medium), color: NSColor(hex: 0x71717a))
    
    // Left status glitch
    let glitchStatus: String
    let glitchColor: NSColor
    if state.activeKey == "F8" {
        glitchStatus = "⚠️ 86ms BOUNCE GLITCH!\nDouble-pause canceled playback"
        glitchColor = NSColor(hex: 0xef4444)
    } else {
        glitchStatus = "Unreliable media key routing\nBrowser tab dropped signal"
        glitchColor = NSColor(hex: 0xa1a1aa)
    }
    drawText(glitchStatus, in: NSRect(x: 35, y: 140, width: 300, height: 45), font: NSFont.systemFont(ofSize: 11, weight: .semibold), color: glitchColor)
    
    // Left bottom badge
    let failBadge = NSRect(x: 35, y: 45, width: 300, height: 40)
    NSColor(hex: 0x3f1212).setFill()
    NSBezierPath(roundedRect: failBadge, xRadius: 8, yRadius: 8).fill()
    drawText("Drop rate: 38% • Double-tap bug", in: NSRect(x: 45, y: 55, width: 280, height: 20), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold), color: NSColor(hex: 0xfca5a5))
    
    // Right Half: With MediaKeysFix (Green / Cyan accent)
    let rightRect = NSRect(x: 370, y: 20, width: 330, height: 360)
    let rightPath = NSBezierPath(roundedRect: rightRect, xRadius: 12, yRadius: 12)
    NSColor(hex: 0x0f1d1b).setFill()
    rightPath.fill()
    NSColor(hex: 0x10b981, alpha: 0.6).setStroke()
    rightPath.lineWidth = 1.5
    rightPath.stroke()
    
    drawText("✅ WITH MEDIAKEYSFIX", in: NSRect(x: 385, y: 345, width: 300, height: 22), font: NSFont.systemFont(ofSize: 14, weight: .heavy), color: NSColor(hex: 0x34d399))
    drawText("Native CGEventTap + 200ms Debounce", in: NSRect(x: 385, y: 325, width: 300, height: 16), font: NSFont.systemFont(ofSize: 11, weight: .regular), color: NSColor(hex: 0x6ee7b7))
    
    // Right Album Cover
    let rightCoverRect = NSRect(x: 385, y: 220, width: 90, height: 90)
    drawCoverImage(state.cover, in: rightCoverRect, radius: 8)
    drawText(state.title, in: NSRect(x: 485, y: 275, width: 200, height: 20), font: NSFont.systemFont(ofSize: 14, weight: .bold), color: NSColor.white)
    drawText(state.artist, in: NSRect(x: 485, y: 255, width: 200, height: 16), font: NSFont.systemFont(ofSize: 11, weight: .medium), color: NSColor(hex: 0x6ee7b7))
    
    // Right key indicator
    let rightAction = state.actionLabel
    drawText("🎯 \(rightAction)", in: NSRect(x: 385, y: 150, width: 300, height: 35), font: NSFont.systemFont(ofSize: 12, weight: .bold), color: NSColor.white)
    
    let eqRight = NSRect(x: 385, y: 115, width: 140, height: 20)
    drawEqualizerBars(in: eqRight, isPlaying: state.isPlaying, frame: frame, color: NSColor(hex: 0x10b981))
    
    let succBadge = NSRect(x: 385, y: 45, width: 300, height: 40)
    NSColor(hex: 0x064e3b).setFill()
    NSBezierPath(roundedRect: succBadge, xRadius: 8, yRadius: 8).fill()
    drawText("0ms duplicate bounce • 100% reliable", in: NSRect(x: 395, y: 55, width: 280, height: 20), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold), color: NSColor(hex: 0xa7f3d0))
}

// VARIANT 3: Background YouTube Music Window + Foreground Active App
func renderVariant3(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Desktop wallpaper
    let bgGrad = NSGradient(colors: [NSColor(hex: 0x181824), NSColor(hex: 0x2d1b38)])!
    bgGrad.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 45)
    
    // Background Window: Safari YouTube Music (slightly dimmed/inactive)
    let ytmRect = NSRect(x: 30, y: 60, width: 440, height: 310)
    let ytmPath = NSBezierPath(roundedRect: ytmRect, xRadius: 10, yRadius: 10)
    NSColor(hex: 0x030303, alpha: 0.95).setFill()
    ytmPath.fill()
    NSColor(white: 1.0, alpha: 0.15).setStroke()
    ytmPath.stroke()
    
    // Titlebar
    NSColor(hex: 0x121212).setFill()
    NSBezierPath(roundedRect: NSRect(x: 30, y: 340, width: 440, height: 30), xRadius: 10, yRadius: 10).fill()
    drawText("🔴 🟡 🟢  Safari — YouTube Music (Background)", in: NSRect(x: 45, y: 347, width: 400, height: 18), font: NSFont.systemFont(ofSize: 11, weight: .medium), color: NSColor(hex: 0xa1a1aa))
    
    // YTM Cover & Track
    let ytmCover = NSRect(x: 50, y: 130, width: 140, height: 140)
    drawCoverImage(state.cover, in: ytmCover, radius: 10)
    
    drawText(state.title, in: NSRect(x: 205, y: 235, width: 250, height: 24), font: NSFont.systemFont(ofSize: 18, weight: .heavy), color: NSColor.white)
    drawText(state.artist, in: NSRect(x: 205, y: 210, width: 250, height: 18), font: NSFont.systemFont(ofSize: 13, weight: .regular), color: NSColor(hex: 0x9ca3af))
    
    // YTM Play/Pause status button
    let playBtnRect = NSRect(x: 205, y: 165, width: 110, height: 32)
    NSColor(white: 1.0, alpha: 0.15).setFill()
    NSBezierPath(roundedRect: playBtnRect, xRadius: 16, yRadius: 16).fill()
    let btnText = state.isPlaying ? "❚❚ Playing" : "▶ Paused"
    drawText(btnText, in: NSRect(x: 215, y: 172, width: 90, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .bold), color: NSColor.white, alignment: .center)
    
    // Foreground Window: Focused Terminal / Code (Overlap right side)
    let fgRect = NSRect(x: 330, y: 30, width: 360, height: 230)
    let fgPath = NSBezierPath(roundedRect: fgRect, xRadius: 10, yRadius: 10)
    NSColor(hex: 0x0f172a, alpha: 0.98).setFill()
    fgPath.fill()
    NSColor(hex: 0x38bdf8, alpha: 0.4).setStroke()
    fgPath.lineWidth = 1.5
    fgPath.stroke()
    
    drawText("🔴 🟡 🟢  Terminal — Work undisturbed", in: NSRect(x: 345, y: 235, width: 330, height: 18), font: NSFont.systemFont(ofSize: 11, weight: .medium), color: NSColor(hex: 0x94a3b8))
    
    drawText("$ npm run build\n[✓] Compiled successfully in 1.4s\n$ git commit -m 'feat: background control'", in: NSRect(x: 345, y: 145, width: 330, height: 60), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), color: NSColor(hex: 0x38bdf8))
    
    // Floating HUD Notification indicating key interception without switching focus
    let hudRect = NSRect(x: 345, y: 45, width: 330, height: 60)
    let hudPath = NSBezierPath(roundedRect: hudRect, xRadius: 8, yRadius: 8)
    NSColor(hex: 0x1e293b).setFill()
    hudPath.fill()
    NSColor(hex: 0x10b981).setStroke()
    hudPath.stroke()
    
    let keyBadge = state.activeKey ?? "F8"
    drawText("⚡ Key: [ \(keyBadge) ] Intercepted", in: NSRect(x: 355, y: 78, width: 310, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .bold), color: NSColor(hex: 0x34d399))
    drawText("Tab controlled in background without switching windows!", in: NSRect(x: 355, y: 55, width: 310, height: 16), font: NSFont.systemFont(ofSize: 10, weight: .medium), color: NSColor(hex: 0xe2e8f0))
}

// VARIANT 4: macOS Menu Bar Tray Popover & Quick Controls
func renderVariant4(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Desktop wallpaper
    let bgGrad = NSGradient(colors: [NSColor(hex: 0x111827), NSColor(hex: 0x1f2937)])!
    bgGrad.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
    
    // Menu Bar at Top
    let barRect = NSRect(x: 0, y: 370, width: CGFloat(width), height: 30)
    NSColor(hex: 0x030712, alpha: 0.95).setFill()
    barRect.fill()
    
    drawText("  Finder  File  Edit  View  Go  Window  Help", in: NSRect(x: 20, y: 376, width: 350, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .regular), color: NSColor(hex: 0xd1d5db))
    
    // Tray Icon & Status
    drawText("🎧 MediaKeysFix   100%   Mon 21:30", in: NSRect(x: 470, y: 376, width: 230, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .medium), color: NSColor(hex: 0x38bdf8))
    
    // Popover Window hanging from Menu Bar
    let popoverRect = NSRect(x: 160, y: 35, width: 400, height: 325)
    let popoverPath = NSBezierPath(roundedRect: popoverRect, xRadius: 14, yRadius: 14)
    NSColor(hex: 0x111827, alpha: 0.98).setFill()
    popoverPath.fill()
    NSColor(white: 1.0, alpha: 0.2).setStroke()
    popoverPath.lineWidth = 1.5
    popoverPath.stroke()
    
    // Popover Header
    drawText("MediaKeysFix Mini-Player", in: NSRect(x: 180, y: 325, width: 250, height: 20), font: NSFont.systemFont(ofSize: 13, weight: .bold), color: NSColor.white)
    drawText("● Running in Tray", in: NSRect(x: 440, y: 326, width: 100, height: 18), font: NSFont.systemFont(ofSize: 11, weight: .semibold), color: NSColor(hex: 0x10b981))
    
    // Centered Album Art
    let coverW: CGFloat = 130
    let coverX = popoverRect.midX - coverW / 2.0
    let coverRect = NSRect(x: coverX, y: 175, width: coverW, height: coverW)
    drawCoverImage(state.cover, in: coverRect, radius: 12)
    
    // Song Info
    drawText(state.title, in: NSRect(x: 180, y: 140, width: 360, height: 22), font: NSFont.systemFont(ofSize: 16, weight: .heavy), color: NSColor.white, alignment: .center)
    drawText(state.artist, in: NSRect(x: 180, y: 120, width: 360, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .medium), color: NSColor(hex: 0x94a3b8), alignment: .center)
    
    // Controls: F7, F8, F9 Key indicators
    let cY: CGFloat = 72
    let cW: CGFloat = 65
    let cH: CGFloat = 40
    let midX = popoverRect.midX
    
    drawKeyCap(rect: NSRect(x: midX - 110, y: cY, width: cW, height: cH), key: "F7", symbol: "⏮", isPressed: state.activeKey == "F7")
    drawKeyCap(rect: NSRect(x: midX - 32, y: cY, width: cW, height: cH), key: "F8", symbol: state.isPlaying ? "❚❚" : "▶", isPressed: state.activeKey == "F8")
    drawKeyCap(rect: NSRect(x: midX + 45, y: cY, width: cW, height: cH), key: "F9", symbol: "⏭", isPressed: state.activeKey == "F9")
    
    // Bottom Action Pill
    let pillRect = NSRect(x: 180, y: 45, width: 360, height: 20)
    drawText(state.actionLabel, in: pillRect, font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold), color: NSColor(hex: 0x38bdf8), alignment: .center)
}

// VARIANT 5: macOS Dynamic Island / Floating Capsule HUD
func renderVariant5(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Minimal dark desktop
    NSColor(hex: 0x050508).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Desktop subtle ambient glow behind HUD
    let glowGrad = NSGradient(colors: [NSColor(hex: 0x1e1b4b, alpha: 0.6), NSColor.clear])!
    glowGrad.draw(in: NSRect(x: 60, y: 180, width: 600, height: 200), angle: 90)
    
    // Expanded Dynamic Island Capsule (Top Center)
    let capsuleRect = NSRect(x: 90, y: 220, width: 540, height: 130)
    let capsulePath = NSBezierPath(roundedRect: capsuleRect, xRadius: 40, yRadius: 40)
    NSColor.black.setFill()
    capsulePath.fill()
    NSColor(white: 1.0, alpha: 0.25).setStroke()
    capsulePath.lineWidth = 1.5
    capsulePath.stroke()
    
    // Left: Thumbnail Album Art
    let thumbRect = NSRect(x: 110, y: 235, width: 100, height: 100)
    drawCoverImage(state.cover, in: thumbRect, radius: 24)
    
    // Center: Track Title & Artist
    drawText(state.title, in: NSRect(x: 225, y: 295, width: 260, height: 24), font: NSFont.systemFont(ofSize: 18, weight: .heavy), color: NSColor.white)
    drawText(state.artist, in: NSRect(x: 225, y: 275, width: 260, height: 18), font: NSFont.systemFont(ofSize: 13, weight: .medium), color: NSColor(hex: 0xa1a1aa))
    
    // Waveform inside capsule
    let eqRect = NSRect(x: 225, y: 245, width: 150, height: 20)
    drawEqualizerBars(in: eqRect, isPlaying: state.isPlaying, frame: frame, color: NSColor(hex: 0xec4899))
    
    // Right: Action Badge inside capsule
    let activeKeyStr = state.activeKey ?? "F8"
    let actionPill = NSRect(x: 485, y: 250, width: 120, height: 50)
    let actionPath = NSBezierPath(roundedRect: actionPill, xRadius: 16, yRadius: 16)
    (state.activeKey != nil ? NSColor(hex: 0x2563eb) : NSColor(hex: 0x1f2937)).setFill()
    actionPath.fill()
    
    drawText(activeKeyStr, in: NSRect(x: 485, y: 275, width: 120, height: 20), font: NSFont.systemFont(ofSize: 14, weight: .heavy), color: NSColor.white, alignment: .center)
    let subStatus = state.isPlaying ? "PLAY" : "PAUSE"
    drawText(subStatus, in: NSRect(x: 485, y: 257, width: 120, height: 16), font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold), color: NSColor(hex: 0x93c5fd), alignment: .center)
    
    // Below Capsule: Explanation HUD
    let bannerRect = NSRect(x: 120, y: 60, width: 480, height: 120)
    let bannerPath = NSBezierPath(roundedRect: bannerRect, xRadius: 16, yRadius: 16)
    NSColor(hex: 0x111827, alpha: 0.8).setFill()
    bannerPath.fill()
    NSColor(white: 1.0, alpha: 0.1).setStroke()
    bannerPath.stroke()
    
    drawText("⚡ Global Background Control", in: NSRect(x: 145, y: 140, width: 430, height: 22), font: NSFont.systemFont(ofSize: 14, weight: .bold), color: NSColor(hex: 0x38bdf8))
    drawText(state.actionLabel, in: NSRect(x: 145, y: 115, width: 430, height: 20), font: NSFont.systemFont(ofSize: 13, weight: .semibold), color: NSColor.white)
    drawText("Debounce: 200ms • Zero lost strokes • Native CGEventTap hook", in: NSRect(x: 145, y: 80, width: 430, height: 18), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), color: NSColor(hex: 0x94a3b8))
}

// VARIANT 6: Spinning Audiophile Vinyl Turntable & VU Meters
func renderVariant6(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Deep carbon background
    NSColor(hex: 0x0d0d11).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Turntable Deck (Left)
    let deckRect = NSRect(x: 40, y: 40, width: 320, height: 320)
    let deckPath = NSBezierPath(roundedRect: deckRect, xRadius: 20, yRadius: 20)
    NSColor(hex: 0x181820).setFill()
    deckPath.fill()
    NSColor(white: 1.0, alpha: 0.1).setStroke()
    deckPath.stroke()
    
    // Vinyl Platter
    let vinylCenter = CGPoint(x: deckRect.midX, y: deckRect.midY)
    let vinylRadius: CGFloat = 135
    let vinylPath = NSBezierPath(ovalIn: NSRect(x: vinylCenter.x - vinylRadius, y: vinylCenter.y - vinylRadius, width: vinylRadius * 2, height: vinylRadius * 2))
    NSColor(hex: 0x050505).setFill()
    vinylPath.fill()
    
    // Vinyl Grooves
    for r in stride(from: 70, to: 130, by: 12) {
        let gPath = NSBezierPath(ovalIn: NSRect(x: vinylCenter.x - CGFloat(r), y: vinylCenter.y - CGFloat(r), width: CGFloat(r * 2), height: CGFloat(r * 2)))
        NSColor(white: 1.0, alpha: 0.05).setStroke()
        gPath.lineWidth = 1.0
        gPath.stroke()
    }
    
    // Vinyl Center Label (Album Art)
    let labelRadius: CGFloat = 45
    let labelRect = NSRect(x: vinylCenter.x - labelRadius, y: vinylCenter.y - labelRadius, width: labelRadius * 2, height: labelRadius * 2)
    drawCoverImage(state.cover, in: labelRect, radius: labelRadius)
    
    // Center Spindle
    let spindle = NSBezierPath(ovalIn: NSRect(x: vinylCenter.x - 7, y: vinylCenter.y - 7, width: 14, height: 14))
    NSColor(hex: 0xd4d4d8).setFill()
    spindle.fill()
    
    // Right Side: Track Info, Studio VU Meters & Function Keys
    let rightX: CGFloat = 390
    drawText("STUDIO VINYL PLAYBACK", in: NSRect(x: rightX, y: 335, width: 300, height: 18), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold), color: NSColor(hex: 0xf59e0b))
    drawText(state.title, in: NSRect(x: rightX, y: 295, width: 300, height: 30), font: NSFont.systemFont(ofSize: 22, weight: .heavy), color: NSColor.white)
    drawText(state.artist, in: NSRect(x: rightX, y: 270, width: 300, height: 20), font: NSFont.systemFont(ofSize: 14, weight: .medium), color: NSColor(hex: 0xa1a1aa))
    
    // Dual VU Meters
    let vuRectL = NSRect(x: rightX, y: 215, width: 135, height: 38)
    let vuRectR = NSRect(x: rightX + 150, y: 215, width: 135, height: 38)
    for (vRect, ch) in [(vuRectL, "CH 1 (L)"), (vuRectR, "CH 2 (R)")] {
        NSColor(hex: 0x1f2430).setFill()
        NSBezierPath(roundedRect: vRect, xRadius: 6, yRadius: 6).fill()
        let vuVal: CGFloat = state.isPlaying ? CGFloat(0.4 + 0.5 * abs(sin(Double(frame) * 0.7))) : 0.08
        let barW = (vRect.width - 8) * vuVal
        let bar = NSRect(x: vRect.minX + 4, y: vRect.minY + 4, width: barW, height: vRect.height - 8)
        (state.isPlaying ? NSColor(hex: 0x10b981) : NSColor(hex: 0x475569)).setFill()
        NSBezierPath(roundedRect: bar, xRadius: 3, yRadius: 3).fill()
        drawText(ch, in: NSRect(x: vRect.minX + 8, y: vRect.minY + 10, width: 100, height: 16), font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold), color: NSColor.white)
    }
    
    // Status & Function Key Badges
    drawText(state.actionLabel, in: NSRect(x: rightX, y: 175, width: 300, height: 22), font: NSFont.systemFont(ofSize: 12, weight: .bold), color: NSColor(hex: 0x38bdf8))
    
    let keyW: CGFloat = 85
    let keyH: CGFloat = 55
    let keyY: CGFloat = 90
    drawKeyCap(rect: NSRect(x: rightX, y: keyY, width: keyW, height: keyH), key: "F7", symbol: "⏮ Prev", isPressed: state.activeKey == "F7")
    drawKeyCap(rect: NSRect(x: rightX + 95, y: keyY, width: keyW, height: keyH), key: "F8", symbol: state.isPlaying ? "❚❚ Pause" : "▶ Play", isPressed: state.activeKey == "F8")
    drawKeyCap(rect: NSRect(x: rightX + 190, y: keyY, width: keyW, height: keyH), key: "F9", symbol: "⏭ Next", isPressed: state.activeKey == "F9")
}

// VARIANT 7: Developer IDE Workstation (Focus undisturbed)
func renderVariant7(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // VS Code dark theme canvas
    NSColor(hex: 0x1e1e1e).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Top Tab Bar
    NSColor(hex: 0x252526).setFill()
    NSRect(x: 0, y: 365, width: CGFloat(width), height: 35).fill()
    drawText("App.swift  ×", in: NSRect(x: 60, y: 374, width: 120, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .medium), color: NSColor.white)
    drawText("MediaKeysFix.swift", in: NSRect(x: 180, y: 374, width: 140, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .regular), color: NSColor(hex: 0x858585))
    
    // Code Area
    let code = """
    1  import Cocoa
    2  import ApplicationServices
    3  
    4  final class MediaKeyInterceptor {
    5      func handleEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
    6          guard isMediaKey(event) else { return Unmanaged.passRetained(event) }
    7          if debounceTimer.isCoolingDown { return nil } // Filter macOS bounce!
    8          sendToYouTubeMusicTab(key: currentKey)
    9          return nil // Suppress duplicate sound
    10     }
    11 }
    """
    drawText(code, in: NSRect(x: 30, y: 90, width: 440, height: 260), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), color: NSColor(hex: 0x9cdcfe))
    
    // Floating Music PiP Widget (Top Right)
    let pipRect = NSRect(x: 430, y: 150, width: 265, height: 195)
    let pipPath = NSBezierPath(roundedRect: pipRect, xRadius: 14, yRadius: 14)
    NSColor(hex: 0x111827, alpha: 0.96).setFill()
    pipPath.fill()
    NSColor(hex: 0x38bdf8, alpha: 0.5).setStroke()
    pipPath.lineWidth = 1.5
    pipPath.stroke()
    
    // Cover in PiP
    let pipCoverRect = NSRect(x: 445, y: 225, width: 100, height: 100)
    drawCoverImage(state.cover, in: pipCoverRect, radius: 10)
    
    drawText(state.title, in: NSRect(x: 555, y: 295, width: 130, height: 20), font: NSFont.systemFont(ofSize: 14, weight: .heavy), color: NSColor.white)
    drawText(state.artist, in: NSRect(x: 555, y: 275, width: 130, height: 18), font: NSFont.systemFont(ofSize: 11, weight: .medium), color: NSColor(hex: 0x94a3b8))
    
    let pipStatus = state.isPlaying ? "PLAYING" : "PAUSED"
    let pipCol = state.isPlaying ? NSColor(hex: 0x10b981) : NSColor(hex: 0xf59e0b)
    drawText(pipStatus, in: NSRect(x: 555, y: 235, width: 130, height: 18), font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold), color: pipCol)
    
    // PiP equalizer
    let eqPip = NSRect(x: 445, y: 195, width: 235, height: 18)
    drawEqualizerBars(in: eqPip, isPlaying: state.isPlaying, frame: frame, color: NSColor(hex: 0x38bdf8))
    
    drawText(state.actionLabel, in: NSRect(x: 445, y: 165, width: 235, height: 18), font: NSFont.systemFont(ofSize: 10, weight: .bold), color: NSColor(hex: 0x34d399))
    
    // Bottom Terminal Status Bar
    let statusRect = NSRect(x: 0, y: 0, width: CGFloat(width), height: 40)
    NSColor(hex: 0x007acc).setFill()
    statusRect.fill()
    drawText("⚡ MediaKeysFix: Intercepted in 1.8ms • Zero focus loss • Work uninterrupted", in: NSRect(x: 20, y: 12, width: 680, height: 20), font: NSFont.systemFont(ofSize: 12, weight: .semibold), color: NSColor.white)
}

// VARIANT 8: macOS Terminal Benchmark & Event Tap Telemetry
func renderVariant8(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Dark terminal
    NSColor(hex: 0x0c0c0e).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Window Header
    NSColor(hex: 0x1c1c24).setFill()
    NSRect(x: 20, y: 350, width: 680, height: 35).fill()
    drawText("🔴 🟡 🟢  mediakeysfix --monitor-telemetry", in: NSRect(x: 35, y: 358, width: 400, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .medium), color: NSColor(hex: 0xa1a1aa))
    
    // Left: Real-time Terminal Log Stream
    let keyStr = state.activeKey ?? "IDLE"
    let logText = """
    [00:01.20] EventTap: Listening on CGEventTapLocation.cghidEventTap
    [00:01.35] Filter: DebounceWindow = 200ms
    [00:02.10] EVENT: NX_KEYTYPE_PLAY (Key \(keyStr)) received
    [00:02.11] DEBOUNCE: Duplicate bounce suppressed (0 dropped)
    [00:02.12] ROUTE: WebKit YouTube Music player updated
    [00:02.13] STATUS: Now Playing -> "\(state.title)" by \(state.artist)
    [00:02.14] STATE: \(state.isPlaying ? "PLAYING" : "PAUSED") [Latency: 2.1ms]
    """
    drawText(logText, in: NSRect(x: 35, y: 140, width: 400, height: 190), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), color: NSColor(hex: 0x4ade80))
    
    // Right: Live Song Card
    let cardRect = NSRect(x: 450, y: 90, width: 240, height: 250)
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 14, yRadius: 14)
    NSColor(hex: 0x181822).setFill()
    cardPath.fill()
    NSColor(hex: 0x4ade80, alpha: 0.4).setStroke()
    cardPath.lineWidth = 1.5
    cardPath.stroke()
    
    // Album Art
    let coverRect = NSRect(x: 470, y: 180, width: 140, height: 140)
    drawCoverImage(state.cover, in: coverRect, radius: 10)
    
    drawText(state.title, in: NSRect(x: 465, y: 145, width: 210, height: 20), font: NSFont.systemFont(ofSize: 15, weight: .heavy), color: NSColor.white, alignment: .center)
    drawText(state.artist, in: NSRect(x: 465, y: 125, width: 210, height: 16), font: NSFont.systemFont(ofSize: 11, weight: .medium), color: NSColor(hex: 0x94a3b8), alignment: .center)
    
    // Action HUD
    drawText(state.actionLabel, in: NSRect(x: 455, y: 100, width: 230, height: 18), font: NSFont.systemFont(ofSize: 10, weight: .bold), color: NSColor(hex: 0x38bdf8), alignment: .center)
    
    // Bottom Keys Bar
    let keyW: CGFloat = 80
    let keyH: CGFloat = 45
    let keyY: CGFloat = 35
    drawKeyCap(rect: NSRect(x: 35, y: keyY, width: keyW, height: keyH), key: "F7", symbol: "⏮ Prev", isPressed: state.activeKey == "F7")
    drawKeyCap(rect: NSRect(x: 125, y: keyY, width: keyW, height: keyH), key: "F8", symbol: state.isPlaying ? "❚❚ Pause" : "▶ Play", isPressed: state.activeKey == "F8")
    drawKeyCap(rect: NSRect(x: 215, y: keyY, width: keyW, height: keyH), key: "F9", symbol: "⏭ Next", isPressed: state.activeKey == "F9")
}

// VARIANT 9: 3D Isometric Floating Glass Cards
func renderVariant9(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Radial cyber gradient
    let bgGrad = NSGradient(colors: [NSColor(hex: 0x0b0e14), NSColor(hex: 0x05070a)])!
    bgGrad.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
    
    // Ambient light cone
    let conePath = NSBezierPath()
    conePath.move(to: CGPoint(x: 360, y: 400))
    conePath.line(to: CGPoint(x: 60, y: 0))
    conePath.line(to: CGPoint(x: 660, y: 0))
    conePath.close()
    NSColor(hex: 0x3b82f6, alpha: 0.06).setFill()
    conePath.fill()
    
    // Title Header
    drawText("ISOMETRIC SIGNAL ROUTER", in: NSRect(x: 40, y: 350, width: 300, height: 20), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold), color: NSColor(hex: 0x60a5fa))
    drawText(state.actionLabel, in: NSRect(x: 320, y: 350, width: 360, height: 20), font: NSFont.systemFont(ofSize: 12, weight: .bold), color: NSColor.white, alignment: .right)
    
    // Left Glass Card: Album Art Showcase
    let card1Rect = NSRect(x: 50, y: 70, width: 280, height: 260)
    let card1Path = NSBezierPath(roundedRect: card1Rect, xRadius: 18, yRadius: 18)
    NSColor(hex: 0x131b2e, alpha: 0.9).setFill()
    card1Path.fill()
    NSColor(hex: 0x60a5fa, alpha: 0.3).setStroke()
    card1Path.lineWidth = 1.5
    card1Path.stroke()
    
    let coverW: CGFloat = 160
    let coverRect = NSRect(x: card1Rect.midX - coverW / 2.0, y: 150, width: coverW, height: coverW)
    drawCoverImage(state.cover, in: coverRect, radius: 14)
    
    drawText(state.title, in: NSRect(x: 65, y: 115, width: 250, height: 22), font: NSFont.systemFont(ofSize: 16, weight: .heavy), color: NSColor.white, alignment: .center)
    drawText(state.artist, in: NSRect(x: 65, y: 92, width: 250, height: 18), font: NSFont.systemFont(ofSize: 12, weight: .medium), color: NSColor(hex: 0x93c5fd), alignment: .center)
    
    // Right Glass Card: Hardware Tap & Debounce Pipeline
    let card2Rect = NSRect(x: 360, y: 70, width: 310, height: 260)
    let card2Path = NSBezierPath(roundedRect: card2Rect, xRadius: 18, yRadius: 18)
    NSColor(hex: 0x0f172a, alpha: 0.9).setFill()
    card2Path.fill()
    NSColor(hex: 0x38bdf8, alpha: 0.3).setStroke()
    card2Path.lineWidth = 1.5
    card2Path.stroke()
    
    drawText("HARDWARE INTERCEPTOR", in: NSRect(x: 380, y: 295, width: 270, height: 18), font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold), color: NSColor(hex: 0x38bdf8))
    
    // Equalizer
    let eqRect = NSRect(x: 380, y: 260, width: 270, height: 22)
    drawEqualizerBars(in: eqRect, isPlaying: state.isPlaying, frame: frame, color: NSColor(hex: 0x60a5fa))
    
    // Keycaps inside Card 2
    let keyW: CGFloat = 75
    let keyH: CGFloat = 55
    let keyY: CGFloat = 175
    drawKeyCap(rect: NSRect(x: 380, y: keyY, width: keyW, height: keyH), key: "F7", symbol: "⏮ Prev", isPressed: state.activeKey == "F7")
    drawKeyCap(rect: NSRect(x: 465, y: keyY, width: keyW, height: keyH), key: "F8", symbol: state.isPlaying ? "❚❚ Pause" : "▶ Play", isPressed: state.activeKey == "F8")
    drawKeyCap(rect: NSRect(x: 550, y: keyY, width: keyW, height: keyH), key: "F9", symbol: "⏭ Next", isPressed: state.activeKey == "F9")
    
    // Latency badge
    let latRect = NSRect(x: 380, y: 95, width: 270, height: 45)
    NSColor(hex: 0x1e293b).setFill()
    NSBezierPath(roundedRect: latRect, xRadius: 8, yRadius: 8).fill()
    drawText("Response Latency: 1.9ms\nStatus: ZERO BOUNCE GUARANTEE", in: NSRect(x: 395, y: 105, width: 240, height: 28), font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold), color: NSColor(hex: 0x34d399))
}

// VARIANT 10: Clean Apple Minimalist High-Contrast Showcase
func renderVariant10(frame: Int) {
    let state = getPlaybackState(frame: frame)
    
    // Pure deep Space Gray
    NSColor(hex: 0x090a0f).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    
    // Main Container
    let container = NSRect(x: 40, y: 30, width: 640, height: 340)
    let cPath = NSBezierPath(roundedRect: container, xRadius: 20, yRadius: 20)
    NSColor(hex: 0x12141c).setFill()
    cPath.fill()
    NSColor(white: 1.0, alpha: 0.12).setStroke()
    cPath.lineWidth = 1.0
    cPath.stroke()
    
    // High-Res Album Art (Left)
    let coverW: CGFloat = 200
    let coverRect = NSRect(x: 70, y: 100, width: coverW, height: coverW)
    drawCoverImage(state.cover, in: coverRect, radius: 16)
    
    // Right: Large Typography & Modern Keycap HUD
    let rightX: CGFloat = 300
    drawText("MEDIAKEYSFIX", in: NSRect(x: rightX, y: 275, width: 350, height: 18), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold), color: NSColor(hex: 0x38bdf8))
    drawText(state.title, in: NSRect(x: rightX, y: 235, width: 350, height: 32), font: NSFont.systemFont(ofSize: 26, weight: .heavy), color: NSColor.white)
    drawText(state.artist, in: NSRect(x: rightX, y: 210, width: 350, height: 22), font: NSFont.systemFont(ofSize: 15, weight: .medium), color: NSColor(hex: 0x94a3b8))
    
    // Progress Bar
    let barRect = NSRect(x: rightX, y: 185, width: 340, height: 6)
    NSColor(white: 1.0, alpha: 0.1).setFill()
    NSBezierPath(roundedRect: barRect, xRadius: 3, yRadius: 3).fill()
    let fillW = max(10, barRect.width * state.progress)
    NSColor(hex: 0x38bdf8).setFill()
    NSBezierPath(roundedRect: NSRect(x: barRect.minX, y: barRect.minY, width: fillW, height: 6), xRadius: 3, yRadius: 3).fill()
    
    // Equalizer
    let eqRect = NSRect(x: rightX, y: 155, width: 140, height: 18)
    drawEqualizerBars(in: eqRect, isPlaying: state.isPlaying, frame: frame, color: state.isPlaying ? NSColor(hex: 0x10b981) : NSColor(hex: 0x64748b))
    
    let playStateLabel = state.isPlaying ? "NOW PLAYING" : "PAUSED"
    let playStateColor = state.isPlaying ? NSColor(hex: 0x10b981) : NSColor(hex: 0xf59e0b)
    drawText(playStateLabel, in: NSRect(x: rightX + 160, y: 157, width: 180, height: 18), font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold), color: playStateColor)
    
    // Function Keys
    let keyW: CGFloat = 85
    let keyH: CGFloat = 55
    let keyY: CGFloat = 85
    drawKeyCap(rect: NSRect(x: rightX, y: keyY, width: keyW, height: keyH), key: "F7", symbol: "⏮ Prev", isPressed: state.activeKey == "F7")
    drawKeyCap(rect: NSRect(x: rightX + 100, y: keyY, width: keyW, height: keyH), key: "F8", symbol: state.isPlaying ? "❚❚ Pause" : "▶ Play", isPressed: state.activeKey == "F8")
    drawKeyCap(rect: NSRect(x: rightX + 200, y: keyY, width: keyW, height: keyH), key: "F9", symbol: "⏭ Next", isPressed: state.activeKey == "F9")
    
    // Bottom Subtitle
    drawText(state.actionLabel, in: NSRect(x: 70, y: 50, width: 570, height: 20), font: NSFont.systemFont(ofSize: 12, weight: .bold), color: NSColor(hex: 0x38bdf8), alignment: .center)
}

// MARK: - Frame Exporter & ffmpeg Pipeline
func renderAndSaveFrame(frame: Int, renderer: (Int) -> Void, to path: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width * 2, // Retina 2x for ultra-sharp text and images
        pixelsHigh: height * 2,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: width, height: height)
    
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    
    // Scale for Retina
    ctx.cgContext.scaleBy(x: 2.0, y: 2.0)
    
    renderer(frame)
    
    NSGraphicsContext.restoreGraphicsState()
    
    guard let pngData = rep.representation(using: .png, properties: [:]) else { return }
    try? pngData.write(to: URL(fileURLWithPath: path))
}

func compileGif(variantIndex: Int) {
    let outputGif = "\(outputDir)/\(variantIndex).gif"
    
    // Use ffmpeg with high-quality palettegen & paletteuse (-nostdin required for non-interactive)
    let cmd = "/opt/homebrew/bin/ffmpeg -nostdin -y -framerate \(fps) -i '\(tempFramesDir)/frame_%03d.png' -vf 'fps=\(fps),scale=720:400:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer' '\(outputGif)'"
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", cmd]
    try? process.run()
    process.waitUntilExit()
}

// MARK: - Main Execution Loop
let variants: [(name: String, renderer: (Int) -> Void)] = [
    ("Physical Keyboard & Floating Music Card", renderVariant1),
    ("Split-Screen: Bounce Bug vs MediaKeysFix", renderVariant2),
    ("Background YouTube Music Tab Control", renderVariant3),
    ("macOS Menu Bar Tray Popover Mini-Player", renderVariant4),
    ("macOS Dynamic Island Floating Capsule HUD", renderVariant5),
    ("Spinning Vinyl Turntable & Studio VU Meters", renderVariant6),
    ("Developer IDE Workspace (Zero Interruption)", renderVariant7),
    ("Terminal Benchmark & EventTap Telemetry", renderVariant8),
    ("Isometric 3D Hardware Signal Pipeline", renderVariant9),
    ("Clean Apple Minimalist High-Contrast Showcase", renderVariant10)
]

for (index, variant) in variants.enumerated() {
    let num = index + 1
    print("==> Generating Variant \(num)/10: \(variant.name)...")
    
    // 1. Render all frames
    for f in 0..<frameCount {
        let framePath = String(format: "%@/frame_%03d.png", tempFramesDir, f)
        renderAndSaveFrame(frame: f, renderer: variant.renderer, to: framePath)
    }
    
    // 2. Compile to GIF
    compileGif(variantIndex: num)
}

print("==> All 10 song-based GIF variants successfully generated into \(outputDir)/!")
