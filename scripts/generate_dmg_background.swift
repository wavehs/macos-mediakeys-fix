import Cocoa

func renderDMGBackground() -> NSImage {
    let width: CGFloat = 540
    let height: CGFloat = 360
    let scale: CGFloat = 2.0 // Retina
    
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    // Background gradient: sleek dark slate / dark gray
    let startColor = NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.22, alpha: 1.0)
    let endColor = NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.14, alpha: 1.0)
    let gradient = NSGradient(starting: startColor, ending: endColor)
    gradient?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -45)
    
    // Draw top subtle border glow
    let borderLine = NSBezierPath()
    borderLine.move(to: NSPoint(x: 0, y: height - 1))
    borderLine.line(to: NSPoint(x: width, y: height - 1))
    NSColor(calibratedWhite: 1.0, alpha: 0.1).setStroke()
    borderLine.lineWidth = 1.0
    borderLine.stroke()
    
    // Middle Arrow and Hint Text
    // Center point: (270, 185)
    let midX: CGFloat = 270
    let midY: CGFloat = 185
    
    // Arrow pointing from Left to Right:
    let arrowPath = NSBezierPath()
    let arrowW: CGFloat = 48
    let arrowH: CGFloat = 16
    let headW: CGFloat = 18
    let headH: CGFloat = 24
    
    let leftX = midX - arrowW / 2.0
    let rightX = midX + arrowW / 2.0
    
    arrowPath.move(to: NSPoint(x: leftX, y: midY - arrowH / 2.0))
    arrowPath.line(to: NSPoint(x: rightX - headW, y: midY - arrowH / 2.0))
    arrowPath.line(to: NSPoint(x: rightX - headW, y: midY - headH / 2.0))
    arrowPath.line(to: NSPoint(x: rightX, y: midY))
    arrowPath.line(to: NSPoint(x: rightX - headW, y: midY + headH / 2.0))
    arrowPath.line(to: NSPoint(x: rightX - headW, y: midY + arrowH / 2.0))
    arrowPath.line(to: NSPoint(x: leftX, y: midY + arrowH / 2.0))
    arrowPath.close()
    
    NSColor(calibratedWhite: 1.0, alpha: 0.25).setFill()
    arrowPath.fill()
    
    // Text: "Drag to Applications to install"
    let font = NSFont.systemFont(ofSize: 13, weight: .medium)
    let textAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(calibratedWhite: 0.75, alpha: 0.85)
    ]
    let text = "Drag to Applications to install" as NSString
    let textSize = text.size(withAttributes: textAttrs)
    let textRect = NSRect(x: (width - textSize.width) / 2.0, y: midY - 60, width: textSize.width, height: textSize.height)
    text.draw(in: textRect, withAttributes: textAttrs)
    
    // Title at top: "MediaKeysFix"
    let titleFont = NSFont.systemFont(ofSize: 18, weight: .bold)
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor(calibratedWhite: 0.95, alpha: 0.95)
    ]
    let title = "MediaKeysFix" as NSString
    let titleSize = title.size(withAttributes: titleAttrs)
    let titleRect = NSRect(x: (width - titleSize.width) / 2.0, y: height - 50, width: titleSize.width, height: titleSize.height)
    title.draw(in: titleRect, withAttributes: titleAttrs)
    
    image.unlockFocus()
    return image
}

let img = renderDMGBackground()
if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try! png.write(to: URL(fileURLWithPath: "resources/dmg_background.png"))
    print("DMG background generated at resources/dmg_background.png")
}
