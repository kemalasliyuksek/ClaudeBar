import SwiftUI

// MARK: - Notification

extension Notification.Name {
    /// Posted whenever a menu bar display setting changes (mode, reset time toggles).
    /// Used to force the status item to remeasure and rebuild the label.
    static let menuBarDisplayChanged = Notification.Name("menuBarDisplayChanged")
}

// MARK: - App

@main
struct ClaudeBarApp: App {
    @State private var service = UsageService()

    /// Incremented whenever a display setting changes.
    /// Changing this @State forces App.body to re-evaluate, which tells macOS
    /// to remeasure the status item and apply the new label width.
    @State private var labelRefreshID = 0

    var body: some Scene {
        MenuBarExtra {
            UsageView()
                .environment(service)
                // Receive the notification posted by UsageService and bump the
                // @State so App.body re-evaluates and the status item resizes.
                .onReceive(NotificationCenter.default.publisher(for: .menuBarDisplayChanged)) { _ in
                    labelRefreshID += 1
                }
        } label: {
            // .id forces SwiftUI to destroy & recreate MenuBarLabelView on each
            // settings change, which triggers macOS to remeasure the status item.
            MenuBarLabelView(service: service)
                .id(labelRefreshID)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Label View

struct MenuBarLabelView: View {
    let service: UsageService

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.medium")

            if service.menuBarSelection == .hourly {
                menuBarText(bucket: service.usage?.fiveHour)
            }

            if service.menuBarSelection == .weekly {
                menuBarText(bucket: service.usage?.sevenDay)
            }
        }
        .fixedSize()
    }

    private func menuBarText(bucket: UsageBucket?) -> some View {
        let percent = bucket?.percent ?? 0
        let text: String
        if service.showResetTime, let rt = resetTimeString(for: bucket) {
            text = "\(percent)% (\(rt))"
        } else {
            text = "\(percent)%"
        }
        return Text(text)
            .font(.caption2)
            .monospacedDigit()
    }

    private func resetTimeString(for bucket: UsageBucket?) -> String? {
        guard let resetDate = bucket?.resetDate else { return nil }
        let seconds = Int(resetDate.timeIntervalSince(Date()))
        guard seconds > 0 else { return nil }
        let days    = seconds / 86400
        let hours   = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0  { return L("time.days_hours", days, hours) }
        if hours > 0 { return L("time.hours_minutes", hours, minutes) }
        return L("time.minutes", minutes)
    }
}
