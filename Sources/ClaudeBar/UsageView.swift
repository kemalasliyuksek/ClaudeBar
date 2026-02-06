import SwiftUI
import ServiceManagement

/// Menu bar popover showing Claude usage limits
struct UsageView: View {
    @Environment(UsageService.self) private var service
    @State private var showSettings = false
    @State private var showAbout = false

    private let barColor = Color.accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let usage = service.usage {
                // Current session section
                sectionHeader("Claude plan usage limits", showPlan: true)
                if let bucket = usage.fiveHour {
                    usageRow(
                        title: "Current session",
                        subtitle: bucket.resetText(style: .relative),
                        bucket: bucket
                    )
                }

                divider

                // Weekly limits section
                sectionHeader("Weekly limits")

                if let bucket = usage.sevenDay {
                    usageRow(
                        title: "All models",
                        subtitle: bucket.resetText(style: .absolute),
                        bucket: bucket
                    )
                }

                if let bucket = usage.sevenDaySonnet {
                    usageRow(
                        title: "Sonnet only",
                        subtitle: bucket.percent == 0 ? "You haven't used Sonnet yet" : bucket.resetText(style: .absolute),
                        bucket: bucket
                    )
                }

                if let bucket = usage.sevenDayOpus, bucket.percent > 0 {
                    usageRow(
                        title: "Opus only",
                        subtitle: bucket.resetText(style: .absolute),
                        bucket: bucket
                    )
                }
                
                // Extra usage section
                if let extra = usage.extraUsage, extra.isEnabled {
                    divider
                    sectionHeader("Extra usage")
                    extraUsageRow(extra)
                }

            } else if let error = service.error {
                errorView(error)
            } else {
                loadingView
            }

            divider
            
            if showSettings {
                settingsPanel
                divider
            }
            
            if showAbout {
                aboutPanel
                divider
            }
            
            footer
        }
        .frame(width: 340)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, showPlan: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            
            Spacer()
            
            if showPlan, let plan = service.planType {
                planBadge(plan)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
    
    // MARK: - Plan Badge
    
    private func planBadge(_ plan: String) -> some View {
        Text("\(plan.capitalized) Plan")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor)
            .clipShape(Capsule())
    }

    // MARK: - Usage Row

    private func usageRow(title: String, subtitle: String?, bucket: UsageBucket) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // First line: title + progress bar + percentage
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 13))
                    .frame(width: 100, alignment: .leading)

                progressBar(percent: bucket.percent)

                Text("\(bucket.percent)% used")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 65, alignment: .trailing)
            }

            // Second line: subtitle
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Extra Usage Row
    
    private func extraUsageRow(_ extra: ExtraUsage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // First line: spent + progress bar + percentage
            HStack(spacing: 12) {
                Text("\(extra.usedAmount) spent")
                    .font(.system(size: 13))
                    .frame(width: 100, alignment: .leading)
                
                progressBar(percent: extra.percent)
                
                Text("\(extra.percent)% used")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 65, alignment: .trailing)
            }
            
            // Second line: reset date + limit
            Text("Resets \(extra.resetDateText) · Limit: \(extra.limitAmount)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Progress Bar

    private func progressBar(percent: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.primary.opacity(0.1))
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: max(4, geo.size.width * CGFloat(min(percent, 100)) / 100))
            }
        }
        .frame(height: 8)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(.primary.opacity(0.1))
            .frame(height: 1)
            .padding(.vertical, 8)
    }

    // MARK: - About Panel
    
    private var aboutPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.system(size: 13, weight: .semibold))
            
            Text("A lightweight menu bar app for monitoring Claude usage limits.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Created by")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                if let url = URL(string: "https://github.com/kemalasliyuksek") {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                            Text("Kemal Aslıyüksek")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                }
            }
            
            HStack(spacing: 12) {
                if let url = URL(string: "https://github.com/kemalasliyuksek/claudebar") {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text("GitHub")
                                .font(.system(size: 11))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                
                if let url = URL(string: "https://github.com/kemalasliyuksek/claudebar/issues") {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.bubble")
                                .font(.system(size: 10))
                            Text("Report Issue")
                                .font(.system(size: 11))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("v1.0.0")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Settings Panel
    
    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.system(size: 13, weight: .semibold))
            
            // General settings
            SettingsRow(title: "Launch at login") {
                Toggle("", isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { newValue in
                        try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: "Show % in menu bar") {
                Toggle("", isOn: Binding(
                    get: { service.showPercentage },
                    set: { service.showPercentage = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: "Refresh interval") {
                Picker("", selection: Binding(
                    get: { service.refreshInterval },
                    set: { service.refreshInterval = $0 }
                )) {
                    Text("30s").tag(30)
                    Text("1m").tag(60)
                    Text("2m").tag(120)
                    Text("5m").tag(300)
                }
                .pickerStyle(.menu)
                .frame(width: 70)
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Notification settings
            HStack {
                Text("Notifications")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Button("Test") {
                    service.sendTestNotification()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            
            SettingsRow(title: "Notify when 50% used") {
                Toggle("", isOn: Binding(
                    get: { service.notifyAt50 },
                    set: { service.notifyAt50 = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: "Notify when 75% used") {
                Toggle("", isOn: Binding(
                    get: { service.notifyAt75 },
                    set: { service.notifyAt75 = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: "Notify when limit reached") {
                Toggle("", isOn: Binding(
                    get: { service.notifyAt100 },
                    set: { service.notifyAt100 = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: "Notify when limit resets") {
                Toggle("", isOn: Binding(
                    get: { service.notifyOnReset },
                    set: { service.notifyOnReset = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            if let date = service.lastUpdate {
                Text("Last updated: \(relativeTime(from: date))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAbout.toggle()
                    if showAbout { showSettings = false }
                }
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(showAbout ? .primary : .secondary)
            .focusable(false)
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings.toggle()
                    if showSettings { showAbout = false }
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(showSettings ? .primary : .secondary)
            .focusable(false)

            Button {
                Task { await service.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .focusable(false)
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .focusable(false)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func relativeTime(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "less than a minute ago"
        } else if seconds < 3600 {
            let mins = seconds / 60
            return "\(mins) minute\(mins == 1 ? "" : "s") ago"
        } else {
            let hrs = seconds / 3600
            return "\(hrs) hour\(hrs == 1 ? "" : "s") ago"
        }
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Loading...")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private func errorView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .padding(20)
    }
}

// MARK: - Settings Row

private struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
            Spacer()
            content()
        }
    }
}
