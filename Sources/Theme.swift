import SwiftUI
import AppKit

/// 색은 상태를 알리는 용도로만 쓴다: 켜짐 = lamp, 꺼짐 = 시스템 회색.
enum Theme {
    static let lamp = Color(nsColor: NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark
            ? NSColor(srgbRed: 0xF0 / 255, green: 0xB0 / 255, blue: 0x4F / 255, alpha: 1)
            : NSColor(srgbRed: 0xD9 / 255, green: 0x8F / 255, blue: 0x1F / 255, alpha: 1)
    })
    static let lampInk = Color(.sRGB, red: 0x1C / 255, green: 0x1F / 255, blue: 0x26 / 255)
    static let chip = Color.primary.opacity(0.08)
    static let track = Color.primary.opacity(0.12)
}

/// 불꽃 윤곽 (18x18, y축 위쪽이 +).
private func flamePath() -> NSBezierPath {
    // 오른쪽으로 살짝 기운 주 불꽃 + 왼쪽에 작은 불꽃 혀
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

/// 메뉴바용 템플릿 아이콘. 켜짐(무한) = 꽉 찬 불꽃, 시간제한 = 시간이 줄수록 낮아지는 불꽃, 꺼짐 = 점선 윤곽.
func menuBarIcon(active: Bool, fraction: Double?) -> NSImage {
    // 지연 렌더링(drawingHandler)이 메뉴바에서 빈 이미지로 나올 수 있어 비트맵에 미리 그린다.
    let image = NSImage(size: NSSize(width: 18, height: 18))
    image.lockFocus()
    NSColor.black.set()
    let flame = flamePath()

    if !active {
        flame.lineWidth = 1.3
        flame.lineJoinStyle = .round
        flame.setLineDash([2.6, 1.6], count: 2, phase: 0)
        flame.stroke()
    } else if let fraction, fraction < 1 {
        // 윤곽은 늘 보이고, 안쪽은 남은 비율만큼 아래에서부터 채운다.
        flame.lineWidth = 1.4
        flame.lineJoinStyle = .round
        flame.stroke()
        NSGraphicsContext.saveGraphicsState()
        flame.addClip()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 18, height: 1.5 + 15 * CGFloat(max(fraction, 0.05)))).fill()
        NSGraphicsContext.restoreGraphicsState()
    } else {
        flame.fill()
    }
    image.unlockFocus()
    image.isTemplate = true
    return image
}
