import SwiftUI
import ServiceManagement

/// Menu bar popover showing Claude usage limits
struct UsageView: View {
    @Environment(UsageService.self) private var service
    @State private var showSettings = false
    @State private var showAbout = false

    private func barColor(for percent: Int) -> Color {
        switch percent {
        case 0..<50: return .green
        case 50..<75: return .yellow
        case 75..<100: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let usage = service.usage {
                sectionHeader(L("section.plan_usage"), showPlan: true)
                if let bucket = usage.fiveHour {
                    usageRow(
                        title: L("usage.current_session"),
                        subtitle: bucket.resetText(style: .relative),
                        bucket: bucket
                    )
                }

                divider

                sectionHeader(L("section.weekly"))

                if let bucket = usage.sevenDay {
                    usageRow(
                        title: L("usage.all_models"),
                        subtitle: bucket.resetText(style: .absolute),
                        bucket: bucket
                    )
                }

                if let bucket = usage.sevenDaySonnet {
                    usageRow(
                        title: L("usage.sonnet_only"),
                        subtitle: bucket.percent == 0 ? L("usage.sonnet_not_used") : bucket.resetText(style: .absolute),
                        bucket: bucket
                    )
                }

                if let bucket = usage.sevenDayOpus, bucket.percent > 0 {
                    usageRow(
                        title: L("usage.opus_only"),
                        subtitle: bucket.resetText(style: .absolute),
                        bucket: bucket
                    )
                }
                
                if let extra = usage.extraUsage, extra.isEnabled {
                    divider
                    sectionHeader(L("section.extra_usage"))
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
        .frame(minWidth: 340, idealWidth: 340)
        .fixedSize(horizontal: true, vertical: false)
        .id(service.languageRefreshID)
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
        Text(L("plan.badge", plan.capitalized))
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
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 13))
                    .frame(width: 100, alignment: .leading)

                progressBar(percent: bucket.percent)

                Text(L("usage.percent_used", bucket.percent))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
            }

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
            HStack(spacing: 12) {
                Text(L("usage.spent", extra.usedAmount))
                    .font(.system(size: 13))
                    .frame(width: 100, alignment: .leading)
                
                progressBar(percent: extra.percent)
                
                Text(L("usage.percent_used", extra.percent))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            Text(L("usage.resets_limit", extra.resetDateText, extra.limitAmount))
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
                    .fill(barColor(for: percent))
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
            Text(L("about.title"))
                .font(.system(size: 13, weight: .semibold))
            
            Text(L("about.description"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(L("about.created_by"))
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
                            Text(L("about.github"))
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
                            Text(L("about.report_issue"))
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
            Text(L("settings.title"))
                .font(.system(size: 13, weight: .semibold))
            
            SettingsRow(title: L("settings.launch_at_login")) {
                Toggle("", isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { newValue in
                        try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: L("settings.show_percentage")) {
                Toggle("", isOn: Binding(
                    get: { service.showPercentage },
                    set: { service.showPercentage = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: L("settings.language")) {
                Picker("", selection: Binding(
                    get: { service.appLanguage },
                    set: { service.appLanguage = $0 }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
            
            SettingsRow(title: L("settings.refresh_interval")) {
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
            
            HStack {
                Text(L("settings.notifications"))
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Button(L("settings.test")) {
                    service.sendTestNotification()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            
            SettingsRow(title: L("settings.notify_50")) {
                Toggle("", isOn: Binding(
                    get: { service.notifyAt50 },
                    set: { service.notifyAt50 = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: L("settings.notify_75")) {
                Toggle("", isOn: Binding(
                    get: { service.notifyAt75 },
                    set: { service.notifyAt75 = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: L("settings.notify_limit")) {
                Toggle("", isOn: Binding(
                    get: { service.notifyAt100 },
                    set: { service.notifyAt100 = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            
            SettingsRow(title: L("settings.notify_reset")) {
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
                Text(L("footer.last_updated", relativeTime(from: date)))
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
            return L("footer.less_than_minute")
        } else if seconds < 3600 {
            let mins = seconds / 60
            return L("footer.minutes_ago", mins)
        } else {
            let hrs = seconds / 3600
            return L("footer.hours_ago", hrs)
        }
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text(L("loading"))
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
