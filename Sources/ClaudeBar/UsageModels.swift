import Foundation

// MARK: - API Response

/// /api/oauth/usage yanıtı.
///
/// Şema Claude Code 2.1.x'in beklediği yapıyla hizalı: her kova null gelebilir,
/// kovanın içindeki utilization da null olabilir ve `limits` dizisi model bazlı
/// haftalık pencereleri (örneğin Fable) taşır. Bilinmeyen alanlar yok sayılır,
/// böylece sunucu yeni alan eklediğinde parse kırılmaz.
struct UsageResponse: Codable, Equatable {
    let fiveHour: UsageBucket?
    let sevenDay: UsageBucket?
    let sevenDaySonnet: UsageBucket?
    let sevenDayOpus: UsageBucket?
    /// Üçüncü taraf OAuth uygulamalarının haftalık penceresi. Claude Code da göstermiyor, biz de göstermiyoruz.
    let sevenDayOAuthApps: UsageBucket?
    /// Tek seferlik kullanım kredisi. API'de "cinder_cove" adıyla geliyor, resets_at son kullanma tarihi.
    let oneTimeCredit: UsageBucket?
    let extraUsage: ExtraUsage?
    let limits: [ScopedLimit]?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
        case sevenDayOAuthApps = "seven_day_oauth_apps"
        case oneTimeCredit = "cinder_cove"
        case extraUsage = "extra_usage"
        case limits
    }

    /// limits[] içindeki model bazlı haftalık kovalar, API sırası korunur
    var modelLimits: [ScopedLimit] {
        (limits ?? []).filter(\.isModelWeekly)
    }
}

/// limits[] dizisinin bir öğesi. Claude Code yalnızca kind == "weekly_scoped" ve
/// scope.model taşıyan öğeleri gösteriyor; diğerleri (yüzey bazlı vb.) atlanıyor.
struct ScopedLimit: Codable, Equatable {
    let kind: String?
    let group: String?
    let percent: Double?
    let resetsAt: String?
    let scope: Scope?

    struct Scope: Codable, Equatable {
        let model: Named?
        let surface: Named?
    }

    struct Named: Codable, Equatable {
        let displayName: String

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case kind, group, percent, scope
        case resetsAt = "resets_at"
    }

    var modelName: String? { scope?.model?.displayName }

    var isModelWeekly: Bool {
        kind == "weekly_scoped" && modelName != nil
    }

    /// Görünüm ve eşik kontrolü diğer kovalarla aynı yolu kullansın diye UsageBucket'a dönüştürür
    var bucket: UsageBucket {
        UsageBucket(utilization: percent, resetsAt: resetsAt)
    }
}

/// Ekstra kullanım (kullandıkça öde) kredileri. Tutarlar cent cinsinden gelir.
struct ExtraUsage: Codable, Equatable {
    let isEnabled: Bool
    let monthlyLimit: Double?
    let usedCredits: Double?
    let utilization: Double?
    let currency: String?
    let disabledReason: String?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case disabledReason = "disabled_reason"
        case utilization, currency
    }

    /// Kapalı olsa bile sunucu bir gerekçe gönderiyorsa bölüm gösterilir; kullanıcı neden kapalı olduğunu görür
    var isVisible: Bool {
        isEnabled || disabledReason != nil
    }

    var usedAmount: String {
        Money.format(cents: usedCredits ?? 0, currency: currency, fractionDigits: 2)
    }

    var limitAmount: String {
        guard let limit = monthlyLimit else { return L("usage.unlimited") }
        return Money.format(cents: limit, currency: currency, fractionDigits: 0)
    }

    var percent: Int {
        if let utilization {
            return Int(utilization.rounded())
        }
        guard let used = usedCredits, let limit = monthlyLimit, limit > 0 else { return 0 }
        return Int((used / limit) * 100)
    }

    /// Sunucunun bilinen kapatma gerekçeleri için yerelleştirilmiş metin, bilinmeyenler için genel mesaj
    var disabledReasonText: String? {
        guard let reason = disabledReason else { return nil }
        switch reason {
        case "org_level_disabled_until", "org_spend_cap_reached", "out_of_credits":
            return L("usage.extra_disabled.\(reason)")
        default:
            return L("usage.extra_disabled.generic")
        }
    }

    /// Aylık limit takvim ayının ilk günü sıfırlanır
    func resetDateText(now: Date = Date()) -> String {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: now)
        guard let month = components.month else { return L("usage.next_month") }
        components.month = month + 1
        components.day = 1

        guard let nextMonth = calendar.date(from: components) else { return L("usage.next_month") }

        let formatter = DateFormatter()
        formatter.locale = activeLocale()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: nextMonth)
    }
}

/// Kullanım kovası. utilization null gelebilir (örneğin planın o penceresi yoksa);
/// bu durumda hasData false olur ve satır gizlenir.
struct UsageBucket: Codable, Equatable {
    let utilization: Double?
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    init(utilization: Double?, resetsAt: String?) {
        self.utilization = utilization
        self.resetsAt = resetsAt
    }

    var hasData: Bool { utilization != nil }

    /// Kullanım yüzdesi (0-100), veri yoksa 0
    var percent: Int {
        Int((utilization ?? 0).rounded())
    }

    var resetDate: Date? {
        ISO8601.parse(resetsAt)
    }

    /// Süre kalmadıysa nil döner; "Resets in 3 hr 56 min" veya "Resets Sat 9:59 AM"
    func resetText(style: ResetStyle, now: Date = Date()) -> String? {
        guard let target = resetDate, target > now else { return nil }

        switch style {
        case .relative:
            let (hours, minutes) = Self.split(seconds: target.timeIntervalSince(now))
            if hours > 0 {
                return L("reset.in_hours_minutes", hours, minutes)
            }
            return L("reset.in_minutes", minutes)

        case .absolute:
            return L("reset.at", Self.absoluteText(for: target))

        case .expires:
            return L("usage.expires", Self.absoluteText(for: target))
        }
    }

    /// Bildirim gövdesi için yalnızca kalan süre: "2 hr 34 min"
    func remainingText(now: Date = Date()) -> String? {
        guard let target = resetDate, target > now else { return nil }
        let (hours, minutes) = Self.split(seconds: target.timeIntervalSince(now))
        if hours > 0 {
            return L("time.hours_minutes", hours, minutes)
        }
        return L("time.minutes", minutes)
    }

    private static func split(seconds: TimeInterval) -> (hours: Int, minutes: Int) {
        let total = Int(seconds)
        return (total / 3600, (total % 3600) / 60)
    }

    /// "Sat 9:59 AM" biçimi; 59. dakika sunucunun yuvarlama artığıdır, tam saate çekilir
    private static func absoluteText(for target: Date) -> String {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: target)
        let rounded = minute >= 59
            ? (calendar.date(byAdding: .minute, value: 1, to: target) ?? target)
            : target

        let locale = activeLocale()
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        let dayFormatter = DateFormatter()
        dayFormatter.locale = locale
        dayFormatter.setLocalizedDateFormatFromTemplate("EEE")
        return "\(dayFormatter.string(from: rounded)) \(timeFormatter.string(from: rounded))"
    }

    enum ResetStyle {
        case relative   // "Resets in 3 hr 56 min"
        case absolute   // "Resets Sat 9:59 AM"
        case expires    // "Expires Sat 9:59 AM" (tek seferlik kredi)
    }
}

// MARK: - Helpers

/// Sunucu tarihleri bazen kesirli saniyeli, bazen düz ISO 8601 gelir; ikisini de kabul et
enum ISO8601 {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: value) { return date }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }
}

/// Cent cinsinden tutarı seçili dilin para biçimiyle yazar; para birimi gelmezse USD varsayılır
enum Money {
    static func format(cents: Double, currency: String?, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = activeLocale()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency?.uppercased() ?? "USD"
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: cents / 100)) ?? String(format: "%.2f", cents / 100)
    }
}

/// Menü başlığındaki plan rozeti. Tier bilgisi varsa "Max 5x", yoksa abonelik türü.
enum PlanBadge {
    static func text(subscriptionType: String?, rateLimitTier: String?) -> String? {
        // Tier "default_claude_max_5x" gibi gelir, çarpanı rozete taşımak Pro ile Max arasındaki farkı gösterir
        if let tier = rateLimitTier,
           let range = tier.range(of: #"max_(\d+x)$"#, options: .regularExpression) {
            let multiplier = tier[range].dropFirst(4)
            return "Max \(multiplier)"
        }
        guard let type = subscriptionType, !type.isEmpty else { return nil }
        // Bazı yanıtlarda "claude_pro" biçimi kullanılıyor, ön eki at
        let normalized = type.hasPrefix("claude_") ? String(type.dropFirst(7)) : type
        return normalized.capitalized
    }
}

// MARK: - Keychain

/// Claude Code'un Keychain'e yazdığı JSON'un bizi ilgilendiren kısmı.
/// Yazarken bu yapı kullanılmaz; ham JSON üzerinde yalnızca token alanları değiştirilir
/// ki Claude Code'un eklediği bilinmeyen alanlar kaybolmasın (bkz. CredentialMerger).
struct KeychainCredentials: Codable, Equatable, Sendable {
    let claudeAiOauth: OAuthCredentials?

    struct OAuthCredentials: Codable, Equatable, Sendable {
        let accessToken: String
        let refreshToken: String?
        /// Milisaniye cinsinden epoch
        let expiresAt: Double?
        let scopes: [String]?
        let subscriptionType: String?
        let rateLimitTier: String?

        /// Claude Code ile aynı eşik: süre dolumuna 5 dakikadan az kaldıysa yenileme zamanı gelmiştir
        func isExpiringSoon(now: Date = Date(), leeway: TimeInterval = 300) -> Bool {
            guard let expiresAt else { return false }
            return (now.timeIntervalSince1970 + leeway) * 1000 >= expiresAt
        }
    }
}

/// Ham kimlik JSON'unda yalnızca token alanlarını günceller, geri kalan her şeyi olduğu gibi bırakır
enum CredentialMerger {
    enum MergeError: Error {
        case notAnObject
        case missingOAuthSection
    }

    static func merge(raw: Data, accessToken: String, refreshToken: String, expiresAt: Date) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: raw) as? [String: Any] else {
            throw MergeError.notAnObject
        }
        guard var oauth = root["claudeAiOauth"] as? [String: Any] else {
            throw MergeError.missingOAuthSection
        }
        oauth["accessToken"] = accessToken
        oauth["refreshToken"] = refreshToken
        // Claude Code milisaniye tamsayı bekliyor; Double yazarsak "1.7e12" gibi bir gösterim riske girer
        oauth["expiresAt"] = Int64(expiresAt.timeIntervalSince1970 * 1000)
        root["claudeAiOauth"] = oauth
        return try JSONSerialization.data(withJSONObject: root, options: [])
    }
}

// MARK: - Token Refresh

/// OAuth token yenileme yanıtı
struct TokenRefreshResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
    }
}
