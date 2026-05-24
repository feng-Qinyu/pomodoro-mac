import AppKit
import UserNotifications

private enum Mode: Int {
    case focus = 0
    case shortBreak = 1
    case longBreak = 2

    var title: String {
        switch self {
        case .focus: return "专注"
        case .shortBreak: return "短休"
        case .longBreak: return "长休"
        }
    }
}

private final class TimerState {
    var focusMinutes = 25
    var shortBreakMinutes = 5
    var longBreakMinutes = 15
    var mode: Mode = .focus
    var remainingSeconds = 25 * 60
    var isRunning = false
    var completedFocus = 0

    var totalSeconds: Int {
        switch mode {
        case .focus: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }

    var timeText: String {
        let seconds = max(0, remainingSeconds)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return 1 - CGFloat(remainingSeconds) / CGFloat(totalSeconds)
    }

    var statusText: String {
        isRunning ? "\(mode.title)中" : mode.title
    }

    func select(_ nextMode: Mode) {
        mode = nextMode
        reset()
    }

    func reset() {
        isRunning = false
        remainingSeconds = totalSeconds
    }

    func applyDurations(focus: Int, shortBreak: Int, longBreak: Int) {
        focusMinutes = max(1, focus)
        shortBreakMinutes = max(1, shortBreak)
        longBreakMinutes = max(1, longBreak)
        reset()
    }

    func tick() -> Bool {
        guard isRunning else { return false }
        remainingSeconds -= 1
        if remainingSeconds > 0 { return false }

        remainingSeconds = 0
        isRunning = false
        return true
    }

    func advanceAfterCompletion() {
        if mode == .focus {
            completedFocus += 1
            mode = completedFocus % 4 == 0 ? .longBreak : .shortBreak
        } else {
            mode = .focus
        }
        remainingSeconds = totalSeconds
        isRunning = false
    }
}

private let tomatoRed = NSColor(calibratedRed: 226 / 255, green: 67 / 255, blue: 51 / 255, alpha: 1)
private let tomatoGreen = NSColor(calibratedRed: 73 / 255, green: 145 / 255, blue: 88 / 255, alpha: 1)
private let tomatoOutline = NSColor(calibratedWhite: 0.08, alpha: 0.90)
private let limbColor = NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.70, alpha: 1)
private let shoeColor = NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.82, alpha: 1)
private let shoeSole = NSColor(calibratedRed: 1.0, green: 0.44, blue: 0.34, alpha: 1)

private final class TomatoView: NSView {
    var state: TimerState? {
        didSet { needsDisplay = true }
    }
    var animationPhase: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let state else { return }

        NSColor(calibratedRed: 1.0, green: 0.973, blue: 0.945, alpha: 1).setFill()
        bounds.fill()

        drawTomato(progress: state.progress, running: state.isRunning, phase: animationPhase)
    }

    private func drawTomato(progress: CGFloat, running: Bool, phase: CGFloat) {
        let energy = max(0.25, 1 - progress * 0.68)
        let stride = running ? sin(phase) : 0
        let counter = running ? sin(phase + .pi) : 0
        let bounce = running ? -abs(sin(phase)) * 7 * energy : 0
        let tomatoRect = bounds.insetBy(dx: 80, dy: 72).offsetBy(dx: 0, dy: bounce)
        let tomato = tomatoPath(in: tomatoRect)

        drawLimbs(in: tomatoRect, stride: stride, counter: counter, energy: energy)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0.10, alpha: 0.20)
        shadow.shadowOffset = NSSize(width: 0, height: -8)
        shadow.shadowBlurRadius = 20
        shadow.set()
        tomatoRed.setFill()
        tomato.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        tomato.addClip()
        let fillHeight = tomatoRect.height * min(1, max(0, progress))
        let greenRect = NSRect(
            x: tomatoRect.minX - 8,
            y: tomatoRect.maxY - fillHeight,
            width: tomatoRect.width + 16,
            height: fillHeight + 8
        )
        tomatoGreen.setFill()
        greenRect.fill()
        NSGraphicsContext.restoreGraphicsState()

        tomatoOutline.setStroke()
        tomato.lineWidth = 5
        tomato.stroke()

        NSColor.white.withAlphaComponent(0.20).setFill()
        NSBezierPath(ovalIn: NSRect(x: tomatoRect.minX + 66, y: tomatoRect.minY + 78, width: 68, height: 42)).fill()

        drawLeaves(in: tomatoRect)
        drawFace(in: tomatoRect, progress: progress)
    }

    private func tomatoPath(in tomatoRect: NSRect) -> NSBezierPath {
        let tomato = NSBezierPath()
        tomato.move(to: CGPoint(x: tomatoRect.midX, y: tomatoRect.minY + 34))
        tomato.curve(
            to: CGPoint(x: tomatoRect.minX + 18, y: tomatoRect.midY + 24),
            controlPoint1: CGPoint(x: tomatoRect.minX + 70, y: tomatoRect.minY - 8),
            controlPoint2: CGPoint(x: tomatoRect.minX - 16, y: tomatoRect.minY + 100)
        )
        tomato.curve(
            to: CGPoint(x: tomatoRect.midX - 10, y: tomatoRect.maxY - 12),
            controlPoint1: CGPoint(x: tomatoRect.minX - 8, y: tomatoRect.maxY - 12),
            controlPoint2: CGPoint(x: tomatoRect.minX + 112, y: tomatoRect.maxY + 18)
        )
        tomato.curve(
            to: CGPoint(x: tomatoRect.maxX - 18, y: tomatoRect.midY + 24),
            controlPoint1: CGPoint(x: tomatoRect.maxX - 112, y: tomatoRect.maxY + 18),
            controlPoint2: CGPoint(x: tomatoRect.maxX + 8, y: tomatoRect.maxY - 12)
        )
        tomato.curve(
            to: CGPoint(x: tomatoRect.midX, y: tomatoRect.minY + 34),
            controlPoint1: CGPoint(x: tomatoRect.maxX + 16, y: tomatoRect.minY + 100),
            controlPoint2: CGPoint(x: tomatoRect.maxX - 70, y: tomatoRect.minY - 8)
        )
        tomato.close()
        return tomato
    }

    private func drawLimbs(in rect: NSRect, stride: CGFloat, counter: CGFloat, energy: CGFloat) {
        let lineWidth: CGFloat = 11
        drawArm(
            from: CGPoint(x: rect.minX + 24, y: rect.midY - 8),
            elbow: CGPoint(x: rect.minX - 28 - 12 * stride, y: rect.midY - 34 - 12 * energy),
            hand: CGPoint(x: rect.minX - 70 - 14 * stride, y: rect.midY - 18 + 12 * stride),
            fist: true,
            lineWidth: lineWidth
        )
        drawArm(
            from: CGPoint(x: rect.maxX - 22, y: rect.midY - 2),
            elbow: CGPoint(x: rect.maxX + 38 + 12 * stride, y: rect.midY + 48),
            hand: CGPoint(x: rect.maxX + 70 + 10 * stride, y: rect.midY + 28 - 18 * stride),
            fist: false,
            lineWidth: lineWidth
        )

        drawLeg(
            hip: CGPoint(x: rect.midX - 54, y: rect.maxY - 24),
            knee: CGPoint(x: rect.midX - 106 - 18 * stride, y: rect.maxY + 34 + 16 * stride),
            foot: CGPoint(x: rect.midX - 136 - 26 * stride, y: rect.maxY + 70 + 20 * stride),
            angle: -18 - 20 * stride,
            lineWidth: lineWidth
        )
        drawLeg(
            hip: CGPoint(x: rect.midX + 56, y: rect.maxY - 22),
            knee: CGPoint(x: rect.midX + 70 + 14 * counter, y: rect.maxY + 42 - 12 * counter),
            foot: CGPoint(x: rect.midX + 126 + 28 * counter, y: rect.maxY + 68 - 18 * counter),
            angle: 14 + 26 * counter,
            lineWidth: lineWidth
        )
    }

    private func drawArm(from: CGPoint, elbow: CGPoint, hand: CGPoint, fist: Bool, lineWidth: CGFloat) {
        let arm = NSBezierPath()
        arm.move(to: from)
        arm.curve(to: hand, controlPoint1: elbow, controlPoint2: elbow)
        limbColor.setStroke()
        arm.lineWidth = lineWidth
        arm.lineCapStyle = .round
        arm.stroke()

        limbColor.setFill()
        let handRect = NSRect(x: hand.x - 15, y: hand.y - 15, width: 30, height: 30)
        NSBezierPath(ovalIn: handRect).fill()
        if fist {
            NSColor(calibratedWhite: 0.18, alpha: 0.45).setStroke()
            for offset in [-7.0, 0.0, 7.0] {
                let knuckle = NSBezierPath()
                knuckle.move(to: CGPoint(x: hand.x - 8, y: hand.y + CGFloat(offset)))
                knuckle.line(to: CGPoint(x: hand.x + 8, y: hand.y + CGFloat(offset) + 3))
                knuckle.lineWidth = 1.5
                knuckle.stroke()
            }
        }
    }

    private func drawLeg(hip: CGPoint, knee: CGPoint, foot: CGPoint, angle: CGFloat, lineWidth: CGFloat) {
        let leg = NSBezierPath()
        leg.move(to: hip)
        leg.curve(to: foot, controlPoint1: knee, controlPoint2: knee)
        limbColor.setStroke()
        leg.lineWidth = lineWidth
        leg.lineCapStyle = .round
        leg.stroke()

        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: foot.x, yBy: foot.y)
        transform.rotate(byDegrees: angle)
        transform.concat()
        shoeColor.setFill()
        let shoe = NSBezierPath(roundedRect: NSRect(x: -32, y: -18, width: 64, height: 36), xRadius: 18, yRadius: 18)
        shoe.fill()
        tomatoOutline.withAlphaComponent(0.72).setStroke()
        shoe.lineWidth = 3
        shoe.stroke()
        shoeSole.setFill()
        NSBezierPath(roundedRect: NSRect(x: -31, y: 8, width: 60, height: 12), xRadius: 8, yRadius: 8).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawLeaves(in rect: NSRect) {
        let leafColor = NSColor(calibratedRed: 43 / 255, green: 126 / 255, blue: 72 / 255, alpha: 1)
        leafColor.setFill()
        let base = CGPoint(x: rect.midX, y: rect.minY + 28)
        for (angle, length) in [(-72.0, 58.0), (-34.0, 64.0), (0.0, 52.0), (34.0, 64.0), (72.0, 58.0)] {
            let radians = CGFloat(angle * .pi / 180)
            let tip = CGPoint(x: base.x + CGFloat(length) * sin(radians), y: base.y - CGFloat(length) * cos(radians))
            let leaf = NSBezierPath()
            leaf.move(to: base)
            leaf.curve(to: tip, controlPoint1: CGPoint(x: base.x - 18, y: base.y - 8), controlPoint2: CGPoint(x: tip.x - 16, y: tip.y + 16))
            leaf.curve(to: base, controlPoint1: CGPoint(x: tip.x + 16, y: tip.y + 16), controlPoint2: CGPoint(x: base.x + 18, y: base.y - 8))
            leaf.close()
            leaf.fill()
        }
    }

    private func drawFace(in rect: NSRect, progress: CGFloat) {
        let fatigue = min(1, max(0, progress))
        let eyeY = rect.minY + 138 + 14 * fatigue
        drawEye(center: CGPoint(x: rect.midX - 48, y: eyeY), fatigue: fatigue, left: true)
        drawEye(center: CGPoint(x: rect.midX + 50, y: eyeY), fatigue: fatigue, left: false)

        tomatoOutline.setStroke()
        if fatigue > 0.25 {
            let tired = (fatigue - 0.25) / 0.75
            let leftOuter = CGPoint(x: rect.midX - 88, y: eyeY - 44 + 20 * tired)
            let leftInner = CGPoint(x: rect.midX - 34, y: eyeY - 58 + 42 * tired)
            let rightInner = CGPoint(x: rect.midX + 34, y: eyeY - 58 + 42 * tired)
            let rightOuter = CGPoint(x: rect.midX + 88, y: eyeY - 44 + 20 * tired)
            drawLine(from: leftOuter, to: leftInner, width: 5)
            drawLine(from: rightInner, to: rightOuter, width: 5)
        }

        NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.55, alpha: 0.65 * (1 - fatigue * 0.35)).setFill()
        NSBezierPath(ovalIn: NSRect(x: rect.midX - 98, y: eyeY + 48, width: 40, height: 20)).fill()
        NSBezierPath(ovalIn: NSRect(x: rect.midX + 58, y: eyeY + 48, width: 40, height: 20)).fill()

        let mouthY = eyeY + 54
        let mouth = NSBezierPath()
        mouth.move(to: CGPoint(x: rect.midX - 42, y: mouthY))
        if fatigue < 0.55 {
            mouth.curve(
                to: CGPoint(x: rect.midX + 44, y: mouthY),
                controlPoint1: CGPoint(x: rect.midX - 18, y: mouthY + 34),
                controlPoint2: CGPoint(x: rect.midX + 18, y: mouthY + 34)
            )
        } else {
            mouth.curve(
                to: CGPoint(x: rect.midX + 40, y: mouthY + 12),
                controlPoint1: CGPoint(x: rect.midX - 12, y: mouthY - 24),
                controlPoint2: CGPoint(x: rect.midX + 14, y: mouthY - 24)
            )
        }
        tomatoOutline.setStroke()
        mouth.lineWidth = 4
        mouth.lineCapStyle = .round
        mouth.stroke()

        if fatigue > 0.62 {
            NSColor(calibratedRed: 0.38, green: 0.70, blue: 0.95, alpha: 0.85).setFill()
            let sweat = NSBezierPath()
            sweat.move(to: CGPoint(x: rect.midX + 94, y: eyeY - 40))
            sweat.curve(to: CGPoint(x: rect.midX + 108, y: eyeY - 8), controlPoint1: CGPoint(x: rect.midX + 120, y: eyeY - 22), controlPoint2: CGPoint(x: rect.midX + 124, y: eyeY - 4))
            sweat.curve(to: CGPoint(x: rect.midX + 94, y: eyeY - 40), controlPoint1: CGPoint(x: rect.midX + 90, y: eyeY - 2), controlPoint2: CGPoint(x: rect.midX + 82, y: eyeY - 20))
            sweat.fill()
        }
    }

    private func drawEye(center: CGPoint, fatigue: CGFloat, left: Bool) {
        let eyeWidth: CGFloat = 70
        let eyeHeight = 46 - 30 * fatigue
        let eyeRect = NSRect(x: center.x - eyeWidth / 2, y: center.y - eyeHeight / 2, width: eyeWidth, height: max(14, eyeHeight))
        NSColor.white.setFill()
        NSBezierPath(roundedRect: eyeRect, xRadius: eyeRect.height / 2, yRadius: eyeRect.height / 2).fill()
        tomatoOutline.setStroke()
        let outline = NSBezierPath(roundedRect: eyeRect, xRadius: eyeRect.height / 2, yRadius: eyeRect.height / 2)
        outline.lineWidth = 4
        outline.stroke()

        let pupilX = center.x + (left ? 2 : -2) - 5 * fatigue
        NSColor(calibratedRed: 0.28, green: 0.16, blue: 0.55, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: pupilX - 10, y: center.y - 12, width: 20, height: 24)).fill()
        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: pupilX - 5, y: center.y - 8, width: 10, height: 14)).fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: pupilX + 1, y: center.y - 10, width: 6, height: 6)).fill()
    }

    private func drawLine(from: CGPoint, to: CGPoint, width: CGFloat) {
        let path = NSBezierPath()
        path.move(to: from)
        path.line(to: to)
        path.lineWidth = width
        path.lineCapStyle = .round
        path.stroke()
    }

    private func drawBrowArc(from: CGPoint, to: CGPoint, control: CGPoint) {
        let path = NSBezierPath()
        path.move(to: from)
        path.curve(to: to, controlPoint1: control, controlPoint2: control)
        path.lineWidth = 5
        path.lineCapStyle = .round
        path.stroke()
    }

    private func drawCentered(_ text: String, y: CGFloat, fontSize: CGFloat, weight: NSFont.Weight, color: NSColor, mono: Bool) {
        let font = mono ? NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: weight) : NSFont.systemFont(ofSize: fontSize, weight: weight)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = text.size(withAttributes: attrs)
        text.draw(at: CGPoint(x: bounds.midX - size.width / 2, y: y), withAttributes: attrs)
    }
}

private final class PillButton: NSButton {
    private let normalColor: NSColor
    private let activeColor: NSColor
    private let disabledColor: NSColor
    private let textColor: NSColor
    var selected = false {
        didSet { refresh() }
    }

    init(title: String, normal: NSColor, active: NSColor, text: NSColor = NSColor(calibratedWhite: 0.15, alpha: 1)) {
        self.normalColor = normal
        self.activeColor = active
        self.disabledColor = NSColor(calibratedWhite: 0.90, alpha: 0.75)
        self.textColor = text
        super.init(frame: .zero)
        self.title = title
        self.isBordered = false
        self.wantsLayer = true
        self.layer?.cornerRadius = 12
        self.layer?.masksToBounds = true
        self.font = .systemFont(ofSize: 15, weight: .semibold)
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isEnabled: Bool {
        didSet { refresh() }
    }

    func refresh() {
        let fill = !isEnabled ? disabledColor : (selected ? activeColor : normalColor)
        layer?.backgroundColor = fill.cgColor
        let color = !isEnabled ? NSColor(calibratedWhite: 0.60, alpha: 1) : (selected ? .white : textColor)
        attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: font as Any, .foregroundColor: color]
        )
    }
}

private final class SpriteTomatoView: NSView {
    var state: TimerState? {
        didSet { needsDisplay = true }
    }
    var animationPhase: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    private let redFrames: [NSImage]
    private let greenFrames: [NSImage]

    override init(frame frameRect: NSRect) {
        redFrames = SpriteTomatoView.loadFrames(suffix: "")
        greenFrames = SpriteTomatoView.loadFrames(suffix: "_green")
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        redFrames = SpriteTomatoView.loadFrames(suffix: "")
        greenFrames = SpriteTomatoView.loadFrames(suffix: "_green")
        super.init(coder: coder)
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor(calibratedRed: 1.0, green: 0.973, blue: 0.945, alpha: 1).setFill()
        bounds.fill()

        guard let state, !redFrames.isEmpty else {
            drawFallback()
            return
        }

        let index = frameIndex(progress: state.progress, running: state.isRunning)
        let target = bounds.insetBy(dx: 0, dy: 0)
        draw(redFrames[index], in: target)

        if index < greenFrames.count && state.progress > 0 {
            NSGraphicsContext.saveGraphicsState()
            let fillHeight = target.height * min(1, max(0, state.progress))
            NSBezierPath(rect: NSRect(x: target.minX, y: target.maxY - fillHeight, width: target.width, height: fillHeight)).addClip()
            draw(greenFrames[index], in: target)
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private static func loadFrames(suffix: String) -> [NSImage] {
        (0..<8).compactMap { index in
            Bundle.main.url(
                forResource: String(format: "frame_%02d%@", index, suffix),
                withExtension: "png",
                subdirectory: "tomato_frames"
            ).flatMap { NSImage(contentsOf: $0) }
        }
    }

    private func frameIndex(progress: CGFloat, running: Bool) -> Int {
        let count = redFrames.count
        guard count > 1 else { return 0 }
        let clamped = min(1, max(0, progress))
        if running {
            let base = min(count - 1, Int(clamped * CGFloat(count)))
            let step = Int(animationPhase) % 2
            if base >= count - 2 {
                return min(count - 1, count - 2 + step)
            }
            return min(count - 1, base + step)
        }
        return min(count - 1, Int(clamped * CGFloat(count)))
    }

    private func draw(_ image: NSImage, in target: NSRect) {
        image.draw(
            in: target,
            from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )
    }

    private func drawFallback() {
        let text = "🍅"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 120),
            .foregroundColor: tomatoRed,
        ]
        let size = text.size(withAttributes: attrs)
        text.draw(at: CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2), withAttributes: attrs)
    }
}

private final class PomodoroController: NSObject {
    private let state = TimerState()
    private let window: NSWindow
    private let tomato = SpriteTomatoView(frame: NSRect(x: 10, y: 144, width: 460, height: 376))
    private let focusModeButton = PillButton(title: "专注", normal: NSColor(calibratedWhite: 0.91, alpha: 1), active: NSColor(calibratedRed: 226 / 255, green: 67 / 255, blue: 51 / 255, alpha: 1))
    private let shortModeButton = PillButton(title: "短休", normal: NSColor(calibratedWhite: 0.91, alpha: 1), active: NSColor(calibratedRed: 73 / 255, green: 145 / 255, blue: 88 / 255, alpha: 1))
    private let longModeButton = PillButton(title: "长休", normal: NSColor(calibratedWhite: 0.91, alpha: 1), active: NSColor(calibratedRed: 73 / 255, green: 145 / 255, blue: 88 / 255, alpha: 1))
    private let timeLabel = NSTextField(labelWithString: "25:00")
    private let statusLabel = NSTextField(labelWithString: "专注")
    private let countLabel = NSTextField(labelWithString: "已完成 0 个番茄")
    private let settingsButton = NSButton(title: "25 / 5", target: nil, action: nil)
    private let startButton = PillButton(title: "开始", normal: NSColor(calibratedRed: 226 / 255, green: 67 / 255, blue: 51 / 255, alpha: 0.95), active: NSColor(calibratedRed: 226 / 255, green: 67 / 255, blue: 51 / 255, alpha: 1), text: .white)
    private let pauseButton = PillButton(title: "暂停", normal: NSColor(calibratedRed: 251 / 255, green: 188 / 255, blue: 5 / 255, alpha: 0.94), active: NSColor(calibratedRed: 251 / 255, green: 188 / 255, blue: 5 / 255, alpha: 1))
    private let resetButton = PillButton(title: "重置", normal: NSColor(calibratedWhite: 0.88, alpha: 1), active: NSColor(calibratedWhite: 0.78, alpha: 1))
    private var timer: Timer?
    private var animationTimer: Timer?
    private var animationPhase: CGFloat = 0

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 640),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        build()
        requestNotifications()
        update()
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func build() {
        window.title = "番茄钟"
        window.isReleasedWhenClosed = false
        let content = NSView(frame: window.contentView!.bounds)
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor(calibratedRed: 1.0, green: 0.973, blue: 0.945, alpha: 1).cgColor
        window.contentView = content

        let title = NSTextField(labelWithString: "番茄钟")
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = NSColor(calibratedWhite: 0.16, alpha: 1)
        title.frame = NSRect(x: 34, y: 584, width: 120, height: 30)
        content.addSubview(title)

        settingsButton.target = self
        settingsButton.action = #selector(openSettings)
        settingsButton.bezelStyle = .rounded
        settingsButton.font = .systemFont(ofSize: 13, weight: .medium)
        settingsButton.frame = NSRect(x: 372, y: 582, width: 74, height: 32)
        content.addSubview(settingsButton)

        layoutModeButton(focusModeButton, x: 44, mode: .focus)
        layoutModeButton(shortModeButton, x: 184, mode: .shortBreak)
        layoutModeButton(longModeButton, x: 324, mode: .longBreak)
        content.addSubview(focusModeButton)
        content.addSubview(shortModeButton)
        content.addSubview(longModeButton)

        tomato.state = state
        content.addSubview(tomato)

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 44, weight: .bold)
        timeLabel.textColor = NSColor(calibratedWhite: 0.12, alpha: 1)
        timeLabel.alignment = .center
        timeLabel.frame = NSRect(x: 70, y: 104, width: 340, height: 48)
        content.addSubview(timeLabel)

        statusLabel.font = .systemFont(ofSize: 17, weight: .medium)
        statusLabel.textColor = NSColor(calibratedWhite: 0.44, alpha: 1)
        statusLabel.alignment = .center
        statusLabel.frame = NSRect(x: 100, y: 78, width: 280, height: 22)
        content.addSubview(statusLabel)

        countLabel.font = .systemFont(ofSize: 12, weight: .regular)
        countLabel.textColor = NSColor(calibratedWhite: 0.52, alpha: 1)
        countLabel.alignment = .center
        countLabel.frame = NSRect(x: 100, y: 56, width: 280, height: 18)
        content.addSubview(countLabel)

        layoutButton(startButton, x: 38, title: "开始", action: #selector(start))
        layoutButton(pauseButton, x: 178, title: "暂停", action: #selector(pause))
        layoutButton(resetButton, x: 318, title: "重置", action: #selector(reset))
        content.addSubview(startButton)
        content.addSubview(pauseButton)
        content.addSubview(resetButton)
    }

    private func layoutModeButton(_ button: PillButton, x: CGFloat, mode: Mode) {
        button.target = self
        button.action = #selector(modeButtonClicked(_:))
        button.tag = mode.rawValue
        button.frame = NSRect(x: x, y: 524, width: 112, height: 46)
    }

    private func layoutButton(_ button: PillButton, x: CGFloat, title: String, action: Selector) {
        button.title = title
        button.target = self
        button.action = action
        button.frame = NSRect(x: x, y: 10, width: 124, height: 42)
    }

    @objc private func modeButtonClicked(_ sender: NSButton) {
        guard let mode = Mode(rawValue: sender.tag) else { return }
        state.select(mode)
        update()
    }

    @objc private func start() {
        state.isRunning = true
        startTicking()
        startAnimating()
        update()
    }

    @objc private func pause() {
        state.isRunning = false
        stopAnimating()
        update()
    }

    @objc private func reset() {
        state.reset()
        stopAnimating()
        update()
    }

    @objc private func openSettings() {
        let alert = NSAlert()
        alert.messageText = "设置时长"
        alert.informativeText = "单位：分钟"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")

        let box = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 108))
        let focusField = settingField(value: state.focusMinutes, y: 78)
        let shortField = settingField(value: state.shortBreakMinutes, y: 42)
        let longField = settingField(value: state.longBreakMinutes, y: 6)
        addSettingRow(box, label: "专注", field: focusField, y: 78)
        addSettingRow(box, label: "短休", field: shortField, y: 42)
        addSettingRow(box, label: "长休", field: longField, y: 6)
        alert.accessoryView = box

        if alert.runModal() == .alertFirstButtonReturn {
            state.applyDurations(
                focus: Int(focusField.stringValue) ?? state.focusMinutes,
                shortBreak: Int(shortField.stringValue) ?? state.shortBreakMinutes,
                longBreak: Int(longField.stringValue) ?? state.longBreakMinutes
            )
            update()
        }
    }

    private func settingField(value: Int, y: CGFloat) -> NSTextField {
        let field = NSTextField(string: "\(value)")
        field.alignment = .center
        field.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        field.frame = NSRect(x: 84, y: y, width: 80, height: 24)
        return field
    }

    private func addSettingRow(_ view: NSView, label: String, field: NSTextField, y: CGFloat) {
        let labelView = NSTextField(labelWithString: label)
        labelView.font = .systemFont(ofSize: 13, weight: .regular)
        labelView.frame = NSRect(x: 24, y: y + 2, width: 48, height: 20)
        view.addSubview(labelView)
        view.addSubview(field)
    }

    private func startTicking() {
        if timer != nil { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let completed = self.state.tick()
            if completed {
                self.stopAnimating()
                self.alertDone()
                self.update()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.state.advanceAfterCompletion()
                    self?.update()
                }
                return
            }
            self.update()
        }
    }

    private func startAnimating() {
        if animationTimer != nil { return }
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 14.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if !self.state.isRunning {
                self.stopAnimating()
                return
            }
            self.animationPhase += 1
            self.tomato.animationPhase = self.animationPhase
        }
    }

    private func stopAnimating() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func update() {
        tomato.animationPhase = animationPhase
        tomato.needsDisplay = true
        timeLabel.stringValue = state.timeText
        statusLabel.stringValue = state.statusText
        countLabel.stringValue = "已完成 \(state.completedFocus) 个番茄"
        settingsButton.title = "\(state.focusMinutes) / \(state.shortBreakMinutes)"
        focusModeButton.selected = state.mode == .focus
        shortModeButton.selected = state.mode == .shortBreak
        longModeButton.selected = state.mode == .longBreak
        startButton.isEnabled = !state.isRunning
        pauseButton.isEnabled = state.isRunning
        startButton.refresh()
        pauseButton.refresh()
        resetButton.refresh()
    }

    private func alertDone() {
        NSSound.beep()
        let content = UNMutableNotificationContent()
        content.title = "番茄钟"
        content.body = "\(state.mode.title)时间到了"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: PomodoroController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = PomodoroController()
        controller?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
