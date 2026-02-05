import SwiftUI

/// Menu bar popover showing Claude usage limits
struct UsageView: View {
    @Environment(UsageService.self) private var service

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

            } else if let error = service.error {
                errorView(error)
            } else {
                loadingView
            }

            divider
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
                Task { await service.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
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
