import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fputs("Usage: swift generate_dmg_background.swift <output-path>\n", stderr)
    exit(1)
}

let outputPath = arguments[1]
let size = NSSize(width: 720, height: 420)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Failed to create bitmap context\n", stderr)
    exit(1)
}

bitmap.size = size

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Failed to create graphics context\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext

let context = graphicsContext.cgContext

let backgroundRect = NSRect(origin: .zero, size: size)
let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 24, yRadius: 24)
backgroundPath.addClip()

let backgroundColors = [
    NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.92, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.92, green: 0.95, blue: 0.99, alpha: 1).cgColor
] as CFArray
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradient = CGGradient(colorsSpace: colorSpace, colors: backgroundColors, locations: [0.0, 1.0])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 40, y: size.height - 40),
    end: CGPoint(x: size.width - 40, y: 20),
    options: []
)

let cardRect = NSRect(x: 28, y: 28, width: size.width - 56, height: size.height - 56)
NSColor.white.withAlphaComponent(0.82).setFill()
NSBezierPath(roundedRect: cardRect, xRadius: 28, yRadius: 28).fill()

let haloRect = NSRect(x: 120, y: 164, width: 132, height: 132)
let haloPath = NSBezierPath(ovalIn: haloRect)
NSColor(calibratedRed: 0.91, green: 0.34, blue: 0.28, alpha: 0.12).setFill()
haloPath.fill()

let title = "将 今历 拖入 Applications"
let subtitle = "安装后即可从菜单栏随时查看农历、节气与节假日"

let titleStyle = NSMutableParagraphStyle()
titleStyle.alignment = .left

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 28, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.13, green: 0.18, blue: 0.24, alpha: 1),
    .paragraphStyle: titleStyle
]

let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 15, weight: .medium),
    .foregroundColor: NSColor(calibratedRed: 0.37, green: 0.43, blue: 0.49, alpha: 1),
    .paragraphStyle: titleStyle
]

(title as NSString).draw(in: NSRect(x: 58, y: 284, width: 360, height: 40), withAttributes: titleAttributes)
(subtitle as NSString).draw(in: NSRect(x: 58, y: 246, width: 400, height: 24), withAttributes: subtitleAttributes)

let badgeRect = NSRect(x: 60, y: 188, width: 110, height: 36)
NSColor(calibratedRed: 0.91, green: 0.34, blue: 0.28, alpha: 1).setFill()
NSBezierPath(roundedRect: badgeRect, xRadius: 18, yRadius: 18).fill()
("菜单栏常驻" as NSString).draw(
    in: NSRect(x: 60, y: 196, width: 110, height: 20),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 14, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: {
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            return style
        }()
    ]
)

let featureRect = NSRect(x: 182, y: 188, width: 94, height: 36)
NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.97, alpha: 1).setFill()
NSBezierPath(roundedRect: featureRect, xRadius: 18, yRadius: 18).fill()
("农历节气" as NSString).draw(
    in: NSRect(x: 182, y: 196, width: 94, height: 20),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 14, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.20, green: 0.26, blue: 0.34, alpha: 1),
        .paragraphStyle: {
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            return style
        }()
    ]
)

let arrow = NSBezierPath()
arrow.move(to: CGPoint(x: 320, y: 140))
arrow.line(to: CGPoint(x: 518, y: 140))
arrow.lineWidth = 7
arrow.lineCapStyle = .round
NSColor(calibratedRed: 0.90, green: 0.42, blue: 0.30, alpha: 0.95).setStroke()
arrow.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: CGPoint(x: 494, y: 118))
arrowHead.line(to: CGPoint(x: 520, y: 140))
arrowHead.line(to: CGPoint(x: 494, y: 162))
arrowHead.lineWidth = 7
arrowHead.lineCapStyle = .round
arrowHead.lineJoinStyle = .round
NSColor(calibratedRed: 0.90, green: 0.42, blue: 0.30, alpha: 0.95).setStroke()
arrowHead.stroke()

let hintAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
    .foregroundColor: NSColor(calibratedRed: 0.90, green: 0.42, blue: 0.30, alpha: 1)
]
("拖到这里完成安装" as NSString).draw(
    in: NSRect(x: 338, y: 160, width: 180, height: 20),
    withAttributes: hintAttributes
)

NSGraphicsContext.restoreGraphicsState()

guard
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render PNG data\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
try pngData.write(to: outputURL)
