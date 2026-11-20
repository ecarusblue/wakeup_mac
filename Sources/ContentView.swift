import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var guardian: SleepGuard

    private let presets: [Int?] = [nil, 30, 60, 120, 240, 480]

    var body: some View {
        VStack(spacing: 16) {
            header
            DialView(
                isActive: guardian.isActive,
                isInfinite: guardian.isActive && guardian.selectedMinutes == nil,
                fraction: guardian.fraction ?? 1,
                big: bigText,
                sub: subText
            )
            chips
            customRow
            footer
        }
        .padding(16)
        .frame(width: 310)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text(guardian.isActive ? "잠들기 방지 중" : "꺼짐")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Toggle("잠들기 방지", isOn: Binding(
                get: { guardian.isActive },
                set: { _ in guardian.toggle() }
            ))
            .toggleStyle(.switch)
            .tint(Theme.lamp)
            .labelsHidden()
        }
    }

    private var chips: some View {
        // 6개 칩을 3열 x 2행으로 배치
        let rows = [Array(presets[0..<3]), Array(presets[3..<6])]
        return VStack(spacing: 6) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 6) {
                    ForEach(rows[r], id: \.self) { minutes in
                        Button(describeMinutes(minutes)) { guardian.start(minutes: minutes) }
                            .buttonStyle(ChipStyle(selected: guardian.isActive && guardian.selectedMinutes == minutes))
                    }
                }
            }
        }
    }

    private var customRow: some View {
        HStack(spacing: 8) {
            Text("직접 설정")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
            Spacer(minLength: 0)
            NumberStepper(value: $guardian.customHours, range: 0...99, step: 1, unit: "시간", wraps: false)
            NumberStepper(value: $guardian.customMinutes, range: 0...59, step: 5, unit: "분", wraps: true)
            Button("적용") {
                guardian.start(minutes: guardian.customHours * 60 + guardian.customMinutes)
            }
            .buttonStyle(ApplyStyle())
            .disabled(guardian.customHours * 60 + guardian.customMinutes == 0)
        }
    }

    private var footer: some View {
        HStack {
            Toggle("화면도 켜 둠", isOn: $guardian.keepDisplayAwake)
                .toggleStyle(.checkbox)
                .tint(Theme.lamp)
                .font(.system(size: 13))
                .help("덮개를 닫으면 설정과 상관없이 맥이 잠들 수 있습니다.")
            Spacer()
            Button("종료") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Text

    private var bigText: String {
        if !guardian.isActive { return "꺼짐" }
        if let remaining = guardian.remaining { return formatDuration(remaining) }
        return "∞"
    }

    private var subText: String {
        if !guardian.isActive { return "다음 시작: \(describeMinutes(guardian.selectedMinutes))" }
        return guardian.selectedMinutes == nil ? "지속 시간 무한" : "남은 시간"
    }
}

// MARK: - Dial

struct DialView: View {
    let isActive: Bool
    let isInfinite: Bool
    let fraction: Double
    let big: String
    let sub: String

    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        ZStack {
            glow
            Circle()
                .stroke(Theme.track, lineWidth: isActive ? 6 : 2)
            Circle()
                .trim(from: 0, to: isActive ? max(fraction, 0.001) : 0)
                .stroke(Theme.lamp, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: fraction)
                .animation(.easeInOut(duration: 0.3), value: isActive)
            VStack(spacing: 2) {
                Text(big)
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(3)
        .frame(width: 176, height: 176)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(big), \(sub)")
    }

    /// 켜져 있을 때만 보이는 은은한 번짐. 무한이면 4초 주기로 숨 쉰다.
    @ViewBuilder private var glow: some View {
        if isActive && isInfinite && !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let level = 0.65 + 0.35 * sin(t * 2 * .pi / 4)
                Circle().fill(Theme.lamp.opacity(0.14 * level))
            }
        } else {
            Circle().fill(Theme.lamp.opacity(isActive ? 0.14 : 0))
        }
    }
}

// MARK: - Controls

struct ChipStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: selected ? .semibold : .regular))
            .foregroundStyle(selected ? Theme.lampInk : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Capsule().fill(selected ? Theme.lamp : Theme.chip))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(Capsule())
    }
}

struct ApplyStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Color(nsColor: .windowBackgroundColor))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.3)
    }
}

struct NumberStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    let wraps: Bool

    var body: some View {
        HStack(spacing: 0) {
            stepButton("minus", delta: -step)
            Text("\(value)\(unit)")
                .font(.system(size: 13))
                .monospacedDigit()
                .frame(minWidth: 38)
                .lineLimit(1)
                .fixedSize()
            stepButton("plus", delta: step)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.chip))
    }

    private func stepButton(_ symbol: String, delta: Int) -> some View {
        Button {
            let span = range.upperBound - range.lowerBound + 1
            var next = value + delta
            if wraps {
                next = range.lowerBound + ((next - range.lowerBound) % span + span) % span
            } else {
                next = min(max(next, range.lowerBound), range.upperBound)
            }
            value = next
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(delta < 0 ? "\(unit) 줄이기" : "\(unit) 늘리기")
    }
}
