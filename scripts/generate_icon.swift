import Cocoa

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    // Scale factor for rendering elements
    let s = size / 1024.0
    
    // Outer squircle bounds (macOS standard squircle padding ~100px on 1024x1024)
    let margin = 100.0 * s
    let squircleRect = NSRect(x: margin, y: margin, width: size - 2 * margin, height: size - 2 * margin)
    let cornerRadius = 180.0 * s
    let squirclePath = NSBezierPath(roundedRect: squircleRect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Shadow
    ctx.saveGState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -18.0 * s)
    shadow.shadowBlurRadius = 30.0 * s
    shadow.set()
    NSColor.black.setFill()
    squirclePath.fill()
    ctx.restoreGState()
    
    // Background gradient
    ctx.saveGState()
    squirclePath.addClip()
    let startColor = NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.22, alpha: 1.0)
    let endColor = NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.10, alpha: 1.0)
    let gradient = NSGradient(starting: startColor, ending: endColor)
    gradient?.draw(in: squircleRect, angle: -45)
    
    // Inner border glow
    let innerPath = NSBezierPath(roundedRect: squircleRect.insetBy(dx: 1.5 * s, dy: 1.5 * s), xRadius: cornerRadius - 1.5 * s, yRadius: cornerRadius - 1.5 * s)
    NSColor(calibratedWhite: 1.0, alpha: 0.12).setStroke()
    innerPath.lineWidth = 3.0 * s
    innerPath.stroke()
    
    // Center glow circle
    let glowCenter = CGPoint(x: size / 2.0, y: size / 2.0)
    let colors = [
        NSColor(calibratedRed: 0.35, green: 0.55, blue: 1.0, alpha: 0.25).cgColor,
        NSColor(calibratedRed: 0.2, green: 0.3, blue: 0.8, alpha: 0.0).cgColor
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let radialGradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(radialGradient, startCenter: glowCenter, startRadius: 0, endCenter: glowCenter, endRadius: 280.0 * s, options: [])
    }
    
    // Draw Media Key Icons (Previous, Play/Pause, Next)
    // Center: Play / Pause in vibrant cyan/blue accent
    let playColor = NSColor(calibratedRed: 0.25, green: 0.75, blue: 1.0, alpha: 0.95)
    let pauseColor = NSColor(calibratedRed: 0.95, green: 0.96, blue: 1.0, alpha: 0.95)
    
    // Left bar of pause:
    let barWidth = 32.0 * s
    let barHeight = 160.0 * s
    let barRadius = 16.0 * s
    let leftBarRect = NSRect(x: 460.0 * s - barWidth, y: (size - barHeight) / 2.0, width: barWidth, height: barHeight)
    let rightBarRect = NSRect(x: 564.0 * s, y: (size - barHeight) / 2.0, width: barWidth, height: barHeight)
    
    pauseColor.setFill()
    NSBezierPath(roundedRect: leftBarRect, xRadius: barRadius, yRadius: barRadius).fill()
    NSBezierPath(roundedRect: rightBarRect, xRadius: barRadius, yRadius: barRadius).fill()
    
    // Previous indicator (left triangle):
    let prevPath = NSBezierPath()
    let prevX: CGFloat = 280.0 * s
    let prevY: CGFloat = size / 2.0
    let triH: CGFloat = 70.0 * s
    let triW: CGFloat = 55.0 * s
    prevPath.move(to: NSPoint(x: prevX, y: prevY))
    prevPath.line(to: NSPoint(x: prevX + triW, y: prevY + triH))
    prevPath.line(to: NSPoint(x: prevX + triW, y: prevY - triH))
    prevPath.close()
    playColor.setFill()
    prevPath.fill()
    
    // Previous bar:
    let prevBar = NSRect(x: prevX - 22.0 * s, y: prevY - triH, width: 14.0 * s, height: triH * 2.0)
    NSBezierPath(roundedRect: prevBar, xRadius: 7.0 * s, yRadius: 7.0 * s).fill()
    
    // Next indicator (right triangle):
    let nextPath = NSBezierPath()
    let nextX: CGFloat = 744.0 * s
    let nextY: CGFloat = size / 2.0
    nextPath.move(to: NSPoint(x: nextX, y: nextY))
    nextPath.line(to: NSPoint(x: nextX - triW, y: nextY + triH))
    nextPath.line(to: NSPoint(x: nextX - triW, y: nextY - triH))
    nextPath.close()
    nextPath.fill()
    
    // Next bar:
    let nextBar = NSRect(x: nextX + 8.0 * s, y: nextY - triH, width: 14.0 * s, height: triH * 2.0)
    NSBezierPath(roundedRect: nextBar, xRadius: 7.0 * s, yRadius: 7.0 * s).fill()
    
    // Text at top: "F7  F8  F9"
    let font = NSFont.monospacedSystemFont(ofSize: 42.0 * s, weight: .bold)
    let textAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(calibratedWhite: 0.65, alpha: 0.85)
    ]
    let label = "F7 • F8 • F9" as NSString
    let labelSize = label.size(withAttributes: textAttrs)
    let labelRect = NSRect(x: (size - labelSize.width) / 2.0, y: size - margin - 90.0 * s, width: labelSize.width, height: labelSize.height)
    label.draw(in: labelRect, withAttributes: textAttrs)
    
    ctx.restoreGState()
    
    image.unlockFocus()
    return image
}

let fileManager = FileManager.default
let iconsetDir = "MediaKeysFix.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try! fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = renderIcon(size: size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let path = "\(iconsetDir)/\(name)"
        try! png.write(to: URL(fileURLWithPath: path))
    }
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", "AppIcon.icns"]
try! task.run()
task.waitUntilExit()

try? fileManager.removeItem(atPath: iconsetDir)
print("AppIcon.icns generated successfully!")
