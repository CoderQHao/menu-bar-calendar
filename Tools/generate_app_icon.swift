import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let sizes = [16, 32, 64, 128, 256, 512, 1024]

func drawIcon(size: Int) -> NSBitmapImageRep {
    let canvas = NSSize(width: size, height: size)
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
        let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
    else {
        fatalError("Failed to create icon bitmap context")
    }

    bitmap.size = canvas

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let bounds = NSRect(origin: .zero, size: canvas)
    let outerRadius = CGFloat(size) * 0.23
    let background = NSBezierPath(roundedRect: bounds, xRadius: outerRadius, yRadius: outerRadius)
    background.addClip()

    let gradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 1.00, green: 0.47, blue: 0.34, alpha: 1),
            NSColor(calibratedRed: 0.90, green: 0.17, blue: 0.20, alpha: 1)
        ]
    )!
    gradient.draw(
        in: background,
        angle: -38
    )

    let glow = NSBezierPath(ovalIn: NSRect(
        x: CGFloat(size) * 0.10,
        y: CGFloat(size) * 0.56,
        width: CGFloat(size) * 0.70,
        height: CGFloat(size) * 0.42
    ))
    NSColor.white.withAlphaComponent(0.13).setFill()
    glow.fill()

    let cardRect = bounds.insetBy(dx: CGFloat(size) * 0.14, dy: CGFloat(size) * 0.14)
    let card = NSBezierPath(
        roundedRect: cardRect,
        xRadius: CGFloat(size) * 0.14,
        yRadius: CGFloat(size) * 0.14
    )
    NSColor(calibratedWhite: 1.0, alpha: 0.97).setFill()
    card.fill()

    let cardShadow = NSShadow()
    cardShadow.shadowColor = NSColor.black.withAlphaComponent(0.10)
    cardShadow.shadowBlurRadius = CGFloat(size) * 0.04
    cardShadow.shadowOffset = NSSize(width: 0, height: -CGFloat(size) * 0.015)
    NSGraphicsContext.saveGraphicsState()
    cardShadow.set()
    card.fill()
    NSGraphicsContext.restoreGraphicsState()

    let topBarHeight = CGFloat(size) * 0.20
    let topBarRect = NSRect(
        x: cardRect.minX,
        y: cardRect.maxY - topBarHeight,
        width: cardRect.width,
        height: topBarHeight
    )
    let topBar = NSBezierPath(
        roundedRect: topBarRect,
        xRadius: CGFloat(size) * 0.14,
        yRadius: CGFloat(size) * 0.14
    )
    NSColor(calibratedRed: 0.95, green: 0.31, blue: 0.27, alpha: 1).setFill()
    topBar.fill()

    let stubWidth = CGFloat(size) * 0.052
    let stubHeight = CGFloat(size) * 0.11
    let stubY = topBarRect.maxY - stubHeight * 0.62
    let stubInset = CGFloat(size) * 0.13
    let leftStub = NSBezierPath(
        roundedRect: NSRect(x: cardRect.minX + stubInset, y: stubY, width: stubWidth, height: stubHeight),
        xRadius: stubWidth / 2,
        yRadius: stubWidth / 2
    )
    let rightStub = NSBezierPath(
        roundedRect: NSRect(x: cardRect.maxX - stubInset - stubWidth, y: stubY, width: stubWidth, height: stubHeight),
        xRadius: stubWidth / 2,
        yRadius: stubWidth / 2
    )
    NSColor(calibratedWhite: 1.0, alpha: 0.85).setFill()
    leftStub.fill()
    rightStub.fill()

    let dayParagraph = NSMutableParagraphStyle()
    dayParagraph.alignment = .center

    let titleString = NSAttributedString(
        string: "今",
        attributes: [
            .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.42, weight: .heavy),
            .foregroundColor: NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.22, alpha: 1),
            .paragraphStyle: dayParagraph
        ]
    )
    titleString.draw(in: NSRect(
        x: cardRect.minX,
        y: cardRect.midY - CGFloat(size) * 0.16,
        width: cardRect.width,
        height: CGFloat(size) * 0.44
    ))

    let accentDotSize = CGFloat(size) * 0.08
    let accentDot = NSBezierPath(ovalIn: NSRect(
        x: cardRect.midX - accentDotSize / 2,
        y: cardRect.minY + CGFloat(size) * 0.12,
        width: accentDotSize,
        height: accentDotSize
    ))
    NSColor(calibratedRed: 0.95, green: 0.31, blue: 0.27, alpha: 1).setFill()
    accentDot.fill()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func savePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AppIconGeneration", code: 1)
    }

    try pngData.write(to: url)
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for size in sizes {
    let bitmap = drawIcon(size: size)
    try savePNG(bitmap, to: outputDirectory.appendingPathComponent("icon_\(size)x\(size).png"))
}
