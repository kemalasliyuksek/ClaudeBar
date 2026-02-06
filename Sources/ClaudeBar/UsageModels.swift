import Foundation

// MARK: - API Response

/// Response from /api/oauth/usage endpoint
struct UsageResponse: Codable {
    let fiveHour: UsageBucket?
    let sevenDay: UsageBucket?
    let sevenDaySonnet: UsageBucket?
    let sevenDayOpus: UsageBucket?
    let extraUsage: ExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
        case extraUsage = "extra_usage"
    }
}

/// Extra usage credits (pay-as-you-go)
struct ExtraUsage: Codable {
    let isEnabled: Bool
    let monthlyLimit: Int?
    let usedCredits: Double?
    let utilization: Double?
    
    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
    
    var usedAmount: String {
        guard let used = usedCredits else { return "$0.00" }
        return String(format: "$%.2f", used / 100)
    }
    
    var limitAmount: String {
        guard let limit = monthlyLimit else { return "unlimited" }
        return String(format: "$%.0f", Double(limit) / 100)
    }
    
    var percent: Int {
        if let utilization = utilization {
            return Int(utilization.rounded())
        }
        guard let used = usedCredits, let limit = monthlyLimit, limit > 0 else { return 0 }
        return Int((used / Double(limit)) * 100)
    }
    
    var resetDateText: String {
        let calendar = Calendar.current
        let now = Date()
        
        var components = calendar.dateComponents([.year, .month], from: now)
        guard let month = components.month else { return "next month" }
        components.month = month + 1
        components.day = 1
        
        guard let nextMonth = calendar.date(from: components) else { return "next month" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: nextMonth)
    }
}

/// Usage bucket with utilization and reset time
struct UsageBucket: Codable {
    let utilization: Double
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    /// Usage as integer percentage (0-100)
    var percent: Int {
        Int(utilization.rounded())
    }

    /// Parsed reset date
    var resetDate: Date? {
        guard let resetsAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: resetsAt)
    }

    /// Format: "Resets in 3 hr 56 min"
    func resetText(style: ResetStyle) -> String? {
        guard let target = resetDate else { return nil }
        let seconds = target.timeIntervalSince(Date())
        guard seconds > 0 else { return nil }

        switch style {
        case .relative:
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            if hours > 0 {
                return "Resets in \(hours) hr \(minutes) min"
            }
            return "Resets in \(minutes) min"

        case .absolute:
            // Round up to nearest hour if within last minute
            let calendar = Calendar.current
            let minute = calendar.component(.minute, from: target)
            let roundedDate: Date
            if minute >= 59 {
                roundedDate = calendar.date(byAdding: .minute, value: 1, to: target) ?? target
            } else {
                roundedDate = target
            }
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEE h:mm a"
            return "Resets \(formatter.string(from: roundedDate))"
        }
    }

    enum ResetStyle {
        case relative  // "Resets in 3 hr 56 min"
        case absolute  // "Resets Sat 9:59 AM"
    }
}

// MARK: - Keychain

/// Claude Code credentials from macOS Keychain
struct KeychainCredentials: Codable {
    let claudeAiOauth: OAuthCredentials?

    struct OAuthCredentials: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Double?
        let scopes: [String]?
        let subscriptionType: String?
        let rateLimitTier: String?
    }
}

// MARK: - Token Refresh

/// OAuth token refresh response
struct TokenRefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
