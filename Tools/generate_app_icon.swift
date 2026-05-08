import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let sizes = [16, 32, 64, 128, 256, 512, 1024]

func drawIcon(size: Int) -> NSImage {
    let canvas = NSSize(width: size, height: size)
    let image = NSImage(size: canvas)

    image.lockFocus()

    let bounds = NSRect(origin: .zero, size: canvas)
    let background = NSBezierPath(roundedRect: bounds, xRadius: CGFloat(size) * 0.22, yRadius: CGFloat(size) * 0.22)
    NSColor(calibratedRed: 0.95, green: 0.28, blue: 0.25, alpha: 1).setFill()
    background.fill()

    let innerInset = CGFloat(size) * 0.12
    let cardRect = bounds.insetBy(dx: innerInset, dy: innerInset)
    let card = NSBezierPath(roundedRect: cardRect, xRadius: CGFloat(size) * 0.12, yRadius: CGFloat(size) * 0.12)
    NSColor.white.setFill()
    card.fill()

    let topBarHeight = CGFloat(size) * 0.22
    let topBarRect = NSRect(x: cardRect.minX, y: cardRect.maxY - topBarHeight, width: cardRect.width, height: topBarHeight)
    let topBar = NSBezierPath(
        roundedRect: topBarRect,
        xRadius: CGFloat(size) * 0.12,
        yRadius: CGFloat(size) * 0.12
    )
    NSColor(calibratedRed: 0.91, green: 0.15, blue: 0.18, alpha: 1).setFill()
    topBar.fill()

    let ringWidth = CGFloat(size) * 0.05
    let ringHeight = CGFloat(size) * 0.11
    let ringY = topBarRect.maxY - ringHeight * 0.65
    let leftRing = NSBezierPath(roundedRect: NSRect(x: cardRect.minX + CGFloat(size) * 0.11, y: ringY, width: ringWidth, height: ringHeight), xRadius: ringWidth / 2, yRadius: ringWidth / 2)
    let rightRing = NSBezierPath(roundedRect: NSRect(x: cardRect.maxX - CGFloat(size) * 0.16, y: ringY, width: ringWidth, height: ringHeight), xRadius: ringWidth / 2, yRadius: ringWidth / 2)
    NSColor(calibratedWhite: 0.90, alpha: 1).setFill()
    leftRing.fill()
    rightRing.fill()

    let dayParagraph = NSMutableParagraphStyle()
    dayParagraph.alignment = .center

    let dayString = NSAttributedString(
        string: "8",
        attributes: [
            .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.33, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.22, alpha: 1),
            .paragraphStyle: dayParagraph
        ]
    )
    dayString.draw(in: NSRect(x: cardRect.minX, y: cardRect.midY - CGFloat(size) * 0.08, width: cardRect.width, height: CGFloat(size) * 0.28))

    let labelString = NSAttributedString(
        string: "周五",
        attributes: [
            .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.12, weight: .semibold),
            .foregroundColor: NSColor(calibratedRed: 0.91, green: 0.15, blue: 0.18, alpha: 1),
            .paragraphStyle: dayParagraph
        ]
    )
    labelString.draw(in: NSRect(x: cardRect.minX, y: cardRect.minY + CGFloat(size) * 0.12, width: cardRect.width, height: CGFloat(size) * 0.12))

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let pngData = rep.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "AppIconGeneration", code: 1)
    }

    try pngData.write(to: url)
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for size in sizes {
    let image = drawIcon(size: size)
    try savePNG(image, to: outputDirectory.appendingPathComponent("icon_\(size)x\(size).png"))
}
