import SwiftUI

@main
struct WakeUpApp: App {
    @StateObject private var guardian = SleepGuard()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(guardian)
        } label: {
            HStack(spacing: 4) {
                Image(nsImage: menuBarIcon(active: guardian.isActive, fraction: guardian.fraction))
                    .renderingMode(.template)
                if let remaining = guardian.remaining {
                    Text(formatDuration(remaining)).monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
