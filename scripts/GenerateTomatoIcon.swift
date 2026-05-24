import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "AppIcon.iconset"
let icnsOutput = CommandLine.arguments.dropFirst().dropFirst().first
try? FileManager.default.removeItem(atPath: output)
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

func drawIcon(size: CGFloat, path: String) throws {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    NSColor(calibratedRed: 1.0, green: 0.965, blue: 0.925, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size), xRadius: size * 0.22, yRadius: size * 0.22).fill()

    let scale = size / 1024
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * scale, y: y * scale)
    }

    let flip = NSAffineTransform()
    flip.translateX(by: 0, yBy: size)
    flip.scaleX(by: 1, yBy: -1)
    flip.concat()

    func drawArm(from: CGPoint, elbow: CGPoint, hand: CGPoint, fist: Bool) {
        let arm = NSBezierPath()
        arm.move(to: from)
        arm.curve(to: hand, controlPoint1: elbow, controlPoint2: elbow)
        arm.lineWidth = 34 * scale
        arm.lineCapStyle = .round
        NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.70, alpha: 1).setStroke()
        arm.stroke()

        NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.70, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: hand.x - 44 * scale, y: hand.y - 44 * scale, width: 88 * scale, height: 88 * scale)).fill()
        if fist {
            NSColor(calibratedWhite: 0.15, alpha: 0.45).setStroke()
            for offset in [-22.0, 0.0, 22.0] {
                let line = NSBezierPath()
                line.move(to: CGPoint(x: hand.x - 24 * scale, y: hand.y + CGFloat(offset) * scale))
                line.line(to: CGPoint(x: hand.x + 28 * scale, y: hand.y + CGFloat(offset + 8) * scale))
                line.lineWidth = max(2, 5 * scale)
                line.stroke()
            }
        }
    }

    func drawLeg(hip: CGPoint, knee: CGPoint, foot: CGPoint, angle: CGFloat) {
        let leg = NSBezierPath()
        leg.move(to: hip)
        leg.curve(to: foot, controlPoint1: knee, controlPoint2: knee)
        leg.lineWidth = 34 * scale
        leg.lineCapStyle = .round
        NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.70, alpha: 1).setStroke()
        leg.stroke()

        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: foot.x, yBy: foot.y)
        transform.rotate(byDegrees: angle)
        transform.concat()
        let shoe = NSBezierPath(roundedRect: NSRect(x: -88 * scale, y: -45 * scale, width: 176 * scale, height: 90 * scale), xRadius: 44 * scale, yRadius: 44 * scale)
        NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.82, alpha: 1).setFill()
        shoe.fill()
        NSColor(calibratedWhite: 0.08, alpha: 0.88).setStroke()
        shoe.lineWidth = max(2, 9 * scale)
        shoe.stroke()
        NSColor(calibratedRed: 1.0, green: 0.44, blue: 0.34, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: -82 * scale, y: -43 * scale, width: 156 * scale, height: 30 * scale), xRadius: 18 * scale, yRadius: 18 * scale).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    drawArm(from: p(260, 552), elbow: p(104, 622), hand: p(78, 512), fist: true)
    drawArm(from: p(764, 548), elbow: p(912, 446), hand: p(934, 568), fist: false)
    drawLeg(hip: p(420, 820), knee: p(260, 900), foot: p(220, 820), angle: 18)
    drawLeg(hip: p(608, 818), knee: p(700, 936), foot: p(812, 888), angle: -20)

    let body = NSBezierPath()
    body.move(to: p(512, 282))
    body.curve(to: p(220, 532), controlPoint1: p(320, 214), controlPoint2: p(190, 350))
    body.curve(to: p(512, 850), controlPoint1: p(158, 732), controlPoint2: p(328, 900))
    body.curve(to: p(804, 532), controlPoint1: p(696, 900), controlPoint2: p(866, 732))
    body.curve(to: p(512, 282), controlPoint1: p(834, 350), controlPoint2: p(704, 214))
    body.close()

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 44 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -18 * scale)
    shadow.shadowColor = NSColor(calibratedWhite: 0.25, alpha: 0.22)
    shadow.set()
    NSColor(calibratedRed: 226 / 255, green: 67 / 255, blue: 51 / 255, alpha: 1).setFill()
    body.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.18).setFill()
    NSBezierPath(ovalIn: NSRect(x: 316 * scale, y: 392 * scale, width: 170 * scale, height: 108 * scale)).fill()

    NSColor(calibratedRed: 38 / 255, green: 124 / 255, blue: 70 / 255, alpha: 1).setFill()
    for angle in [-64.0, -30.0, 0.0, 30.0, 64.0] {
        let radians = CGFloat(angle * .pi / 180)
        let base = p(512, 302)
        let tip = CGPoint(x: base.x + 190 * scale * sin(radians), y: base.y - 190 * scale * cos(radians))
        let leaf = NSBezierPath()
        leaf.move(to: base)
        leaf.curve(to: tip, controlPoint1: CGPoint(x: base.x - 58 * scale, y: base.y - 28 * scale), controlPoint2: CGPoint(x: tip.x - 42 * scale, y: tip.y + 58 * scale))
        leaf.curve(to: base, controlPoint1: CGPoint(x: tip.x + 42 * scale, y: tip.y + 58 * scale), controlPoint2: CGPoint(x: base.x + 58 * scale, y: base.y - 28 * scale))
        leaf.close()
        leaf.fill()
    }

    NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 366 * scale, y: 548 * scale, width: 70 * scale, height: 72 * scale)).fill()
    NSBezierPath(ovalIn: NSRect(x: 588 * scale, y: 548 * scale, width: 70 * scale, height: 72 * scale)).fill()

    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: 406 * scale, y: 582 * scale, width: 18 * scale, height: 18 * scale)).fill()
    NSBezierPath(ovalIn: NSRect(x: 628 * scale, y: 582 * scale, width: 18 * scale, height: 18 * scale)).fill()

    let smile = NSBezierPath()
    smile.move(to: p(414, 698))
    smile.curve(to: p(610, 698), controlPoint1: p(464, 754), controlPoint2: p(560, 754))
    smile.lineWidth = max(5, 24 * scale)
    smile.lineCapStyle = .round
    NSColor(calibratedWhite: 0.12, alpha: 1).setStroke()
    smile.stroke()

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let data = rep.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "Icon", code: 1)
    }
    try data.write(to: URL(fileURLWithPath: path))
}

let icons: [(CGFloat, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (size, name) in icons {
    try drawIcon(size: size, path: "\(output)/\(name)")
}

if let icnsOutput {
    let iconTypes: [(String, String)] = [
        ("icp4", "icon_16x16.png"),
        ("ic11", "icon_16x16@2x.png"),
        ("icp5", "icon_32x32.png"),
        ("ic12", "icon_32x32@2x.png"),
        ("ic07", "icon_128x128.png"),
        ("ic13", "icon_128x128@2x.png"),
        ("ic08", "icon_256x256.png"),
        ("ic14", "icon_256x256@2x.png"),
        ("ic09", "icon_512x512.png"),
        ("ic10", "icon_512x512@2x.png"),
    ]

    var entries = Data()
    for (type, name) in iconTypes {
        let png = try Data(contentsOf: URL(fileURLWithPath: "\(output)/\(name)"))
        entries.append(type.data(using: .ascii)!)
        var length = UInt32(png.count + 8).bigEndian
        entries.append(Data(bytes: &length, count: 4))
        entries.append(png)
    }

    var icns = Data()
    icns.append("icns".data(using: .ascii)!)
    var totalLength = UInt32(entries.count + 8).bigEndian
    icns.append(Data(bytes: &totalLength, count: 4))
    icns.append(entries)
    try icns.write(to: URL(fileURLWithPath: icnsOutput))
}
