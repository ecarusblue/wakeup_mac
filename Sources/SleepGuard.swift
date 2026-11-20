import Foundation
import IOKit.pwr_mgt

/// 전원 어서션으로 잠들기를 방지하고, 지속 시간(무한/지정)을 관리한다.
@MainActor
final class SleepGuard: ObservableObject {
    @Published private(set) var isActive = false
    /// nil = 무한
    @Published private(set) var selectedMinutes: Int? = nil
    @Published private(set) var endDate: Date?
    @Published private(set) var now = Date()
    // 사용자 지정 입력값 (CLT 환경에서 @State 매크로를 쓸 수 없어 여기에 둔다)
    @Published var customHours = 1
    @Published var customMinutes = 0

    @Published var keepDisplayAwake: Bool {
        didSet {
            UserDefaults.standard.set(keepDisplayAwake, forKey: "keepDisplayAwake")
            if isActive { applyAssertions() }
        }
    }

    private var assertionIDs: [IOPMAssertionID] = []
    private var timer: Timer?

    init() {
        keepDisplayAwake = UserDefaults.standard.object(forKey: "keepDisplayAwake") as? Bool ?? true
        start(minutes: nil) // 앱 실행 즉시 활성화, 기본값 무한
    }

    // MARK: - Public

    func start(minutes: Int?) {
        selectedMinutes = minutes
        endDate = minutes.map { Date().addingTimeInterval(TimeInterval($0 * 60)) }
        now = Date()
        isActive = true
        applyAssertions()
        startTimer()
    }

    func stop() {
        isActive = false
        endDate = nil
        releaseAssertions()
        timer?.invalidate()
        timer = nil
    }

    func toggle() {
        isActive ? stop() : start(minutes: selectedMinutes)
    }

    /// 남은 비율 (0...1). 무한이거나 꺼져 있으면 nil.
    var fraction: Double? {
        guard isActive, let minutes = selectedMinutes, let remaining else { return nil }
        return min(1, remaining / TimeInterval(minutes * 60))
    }

    var remaining: TimeInterval? {
        guard isActive, let endDate else { return nil }
        return max(0, endDate.timeIntervalSince(now))
    }

    // MARK: - Assertions

    private func applyAssertions() {
        releaseAssertions()
        var types = [kIOPMAssertionTypePreventUserIdleSystemSleep as String]
        if keepDisplayAwake {
            types.append(kIOPMAssertionTypePreventUserIdleDisplaySleep as String)
        }
        for type in types {
            var id = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                type as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "WakeUp keeping Mac awake" as CFString,
                &id
            )
            if result == kIOReturnSuccess { assertionIDs.append(id) }
        }
    }

    private func releaseAssertions() {
        assertionIDs.forEach { IOPMAssertionRelease($0) }
        assertionIDs.removeAll()
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        now = Date()
        if let endDate, now >= endDate { stop() }
    }
}

// MARK: - Formatting

func formatDuration(_ seconds: TimeInterval) -> String {
    let total = Int(seconds.rounded(.up))
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
}

func describeMinutes(_ minutes: Int?) -> String {
    guard let minutes else { return "무한" }
    let h = minutes / 60, m = minutes % 60
    switch (h, m) {
    case (0, _): return "\(m)분"
    case (_, 0): return "\(h)시간"
    default: return "\(h)시간 \(m)분"
    }
}
