// 앱 아이콘(AppIcon.icns) 생성기. 사용법: swiftc tools/make_icon.swift -o <bin> && <bin> <출력 iconset 폴더>
import AppKit

func flame() -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: 9, y: 1.5))
    p.curve(to: NSPoint(x: 3.8, y: 7.2), controlPoint1: NSPoint(x: 5.8, y: 1.5), controlPoint2: NSPoint(x: 3.8, y: 4))
    p.curve(to: NSPoint(x: 6.4, y: 12.4), controlPoint1: NSPoint(x: 3.8, y: 9.8), controlPoint2: NSPoint(x: 5.2, y: 11.2))
    p.curve(to: NSPoint(x: 8, y: 9.6), controlPoint1: NSPoint(x: 6.5, y: 11), controlPoint2: NSPoint(x: 7.2, y: 10.2))
    p.curve(to: NSPoint(x: 11, y: 16.8), controlPoint1: NSPoint(x: 8, y: 12.2), controlPoint2: NSPoint(x: 9.4, y: 14.8))
    p.curve(to: NSPoint(x: 14.2, y: 7.8), controlPoint1: NSPoint(x: 13.2, y: 14.4), controlPoint2: NSPoint(x: 14.2, y: 11))
    p.curve(to: NSPoint(x: 9, y: 1.5), controlPoint1: NSPoint(x: 14.2, y: 4.2), controlPoint2: NSPoint(x: 12.2, y: 1.5))
    p.close()
    return p
}

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
}

func render(pixels: Int) -> Data {
    let s = CGFloat(pixels)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // macOS 아이콘 그리드: 1024 캔버스 안의 824 사각형, 모서리 반지름 약 22.4%
    let body = NSRect(x: s * 0.0977, y: s * 0.0977, width: s * 0.8047, height: s * 0.8047)
    let shape = NSBezierPath(roundedRect: body, xRadius: body.width * 0.2237, yRadius: body.width * 0.2237)

    // 밤 배경
    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    NSGradient(starting: rgb(0x2C303B), ending: rgb(0x14161B))!.draw(in: body, angle: -90)

    // 불빛 번짐
    let center = NSPoint(x: body.midX, y: body.midY - body.height * 0.02)
    NSGradient(colors: [rgb(0xF0B04F, 0.42), rgb(0xF0B04F, 0.0)])!
        .draw(fromCenter: center, radius: 0, toCenter: center, radius: body.width * 0.46, options: [])

    // 불꽃: 18x18 좌표계를 아이콘 크기에 맞춰 확대
    let scale = body.width * 0.60 / 15.3
    func placed(_ k: CGFloat, dy: CGFloat) -> NSBezierPath {
        let p = flame()
        var t = AffineTransform.identity
        t.translate(x: body.midX, y: body.midY + dy)
        t.scale(x: scale * k, y: scale * k)
        t.translate(x: -9, y: -9.15)
        p.transform(using: t)
        return p
    }
    let outer = placed(1.0, dy: 0)
    NSGradient(starting: rgb(0xFFC25E), ending: rgb(0xE0861A))!.draw(in: outer, angle: -90)
    // 안쪽 심지
    let inner = placed(0.5, dy: -body.height * 0.115)
    NSGradient(starting: rgb(0xFFF1C9), ending: rgb(0xFFD27A))!.draw(in: inner, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let dir = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in sizes {
    try! render(pixels: px).write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
}
