import Foundation

/// Kullanım verisini toplayan, ayarları tutan ve bildirimleri tetikleyen merkez.
///
/// Akış: kimlik bilgisini oku → süresi dolmak üzereyse token yenile → kullanım API'sini çağır →
/// eşikleri kontrol edip bildirim gönder. Token yenileme Claude Code ile aynı kilit protokolünü
/// izler (bkz. freshToken), böylece iki taraf aynı refresh token'ı çift kullanıp birbirini
/// oturumdan düşürmez.
@MainActor
@Observable
final class UsageService {

    // MARK: - Public State

    private(set) var usage: UsageResponse?
    private(set) var error: String?
    private(set) var lastUpdate: Date?
    private(set) var isLoading = false
    private(set) var planType: String?
    private(set) var languageRefreshID = 0
    /// Kullanıcı bildirim iznini reddettiyse true; ayarlar panelinde uyarı gösterilir
    private(set) var notificationsDenied = false

    // MARK: - Settings (persisted)

    var showPercentage: Bool {
        didSet { UserDefaults.standard.set(showPercentage, forKey: "showPercentage") }
    }

    var refreshInterval: Int {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
            restartPolling()
        }
    }

    var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage")
            invalidateBundleCache()
            languageRefreshID += 1
        }
    }

    // MARK: - Notification Settings (persisted)

    var notifyAt50: Bool {
        didSet { UserDefaults.standard.set(notifyAt50, forKey: "notifyAt50") }
    }

    var notifyAt75: Bool {
        didSet { UserDefaults.standard.set(notifyAt75, forKey: "notifyAt75") }
    }

    var notifyAt100: Bool {
        didSet { UserDefaults.standard.set(notifyAt100, forKey: "notifyAt100") }
    }

    var notifyOnReset: Bool {
        didSet { UserDefaults.standard.set(notifyOnReset, forKey: "notifyOnReset") }
    }

    // MARK: - Dependencies

    private let store: CredentialStore
    private let client: OAuthClient
    private let notifier: Notifier
    /// Kova anahtarı → son görülen durum; eşik geçişleri buradan hesaplanır
    private var previous: [String: BucketSnapshot] = [:]
    /// Sunucunun invalid_grant dediği refresh token; aynı token ile her yoklamada tekrar denemek anlamsız
    private var deadRefreshToken: String?
    private var timer: Timer?

    // MARK: - Lifecycle

    init() {
        store = CredentialStore()
        client = OAuthClient()
        notifier = Notifier()

        let defaults = UserDefaults.standard
        showPercentage = defaults.object(forKey: "showPercentage") as? Bool ?? true
        refreshInterval = defaults.object(forKey: "refreshInterval") as? Int ?? 60
        notifyAt50 = defaults.object(forKey: "notifyAt50") as? Bool ?? true
        notifyAt75 = defaults.object(forKey: "notifyAt75") as? Bool ?? true
        notifyAt100 = defaults.object(forKey: "notifyAt100") as? Bool ?? true
        notifyOnReset = defaults.object(forKey: "notifyOnReset") as? Bool ?? false
        let langRaw = defaults.string(forKey: "appLanguage") ?? "system"
        appLanguage = AppLanguage(rawValue: langRaw) ?? .system

        Task { [weak self] in
            guard let self else { return }
            if let granted = await notifier.requestAuthorization() {
                notificationsDenied = !granted
            }
        }
        Task { await refresh() }
        startPolling()
    }

    deinit {
        MainActor.assumeIsolated {
            timer?.invalidate()
        }
    }

    // MARK: - Public Methods

    /// En güncel kullanım verisini çeker
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        guard let snapshot = await readCredentials() else {
            error = L("error.not_logged_in")
            return
        }
        guard let oauth = snapshot.oauth else {
            error = L("error.no_access_token")
            return
        }

        planType = PlanBadge.text(subscriptionType: oauth.subscriptionType, rateLimitTier: oauth.rateLimitTier)

        // Süresi dolmak üzereyse boşa 401 yemek yerine önce yenile
        var token = oauth.accessToken
        if oauth.isExpiringSoon() {
            guard let fresh = await freshToken(replacing: snapshot) else { return }
            token = fresh
        }

        switch await client.fetchUsage(token: token) {
        case .success(let data):
            parse(data)

        case .unauthorized:
            // expiresAt güncel olmasa da sunucu reddettiyse yenile ve bir kez daha dene
            guard let fresh = await freshToken(replacing: snapshot) else { return }
            if case .success(let data) = await client.fetchUsage(token: fresh) {
                parse(data)
            } else {
                error = L("error.request_failed")
            }

        case .failure(let message):
            error = message
        }
    }

    // MARK: - Parsing

    private func parse(_ data: Data) {
        do {
            let decoded = try JSONDecoder().decode(UsageResponse.self, from: data)
            notifyThresholds(for: decoded)
            usage = decoded
            error = nil
            lastUpdate = Date()
        } catch {
            self.error = L("error.parse")
        }
    }

    // MARK: - Token Refresh

    /// Yarış güvenli token yenileme. Claude Code'un kendi akışıyla aynı adımlar:
    /// 1. Yenileme kilidini al (~/.claude.lock). Alınamazsa Claude Code büyük olasılıkla şu an yeniliyor.
    /// 2. Depoyu yeniden oku. Token bu arada değiştiyse başkası yenilemiştir, onu kullan ve çık.
    /// 3. Değişmediyse refresh token ile yenile, sonucu ham JSON'a işleyip depoya yaz.
    private func freshToken(replacing stale: CredentialStore.Snapshot) async -> String? {
        let lock = DirectoryLock(path: store.refreshLockPath)
        let locked = await lock.acquire(retries: 5, minDelay: 1.0, maxDelay: 2.0)
        defer { if locked { lock.release() } }

        guard let current = await readCredentials(), let oauth = current.oauth else {
            error = L("error.not_logged_in")
            return nil
        }
        if oauth.accessToken != stale.oauth?.accessToken, !oauth.isExpiringSoon() {
            return oauth.accessToken
        }
        guard locked else {
            error = L("error.refresh_in_progress")
            return nil
        }
        guard let refreshToken = oauth.refreshToken else {
            error = L("error.no_refresh_token")
            return nil
        }
        guard refreshToken != deadRefreshToken else {
            error = L("error.login_required")
            return nil
        }

        let stored = oauth.scopes ?? []
        do {
            let response: TokenRefreshResponse
            do {
                let scopes = stored.isEmpty ? OAuthClient.defaultScopes : OAuthClient.mergedScopes(stored: stored)
                response = try await client.refresh(refreshToken: refreshToken, scopes: scopes)
            } catch OAuthClient.RefreshError.invalidScope where !stored.isEmpty {
                // Birleştirilmiş küme reddedildiyse token'ın verildiği scope'larla yeniden dene
                response = try await client.refresh(refreshToken: refreshToken, scopes: stored)
            }

            let expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn ?? 3600))
            let merged = try CredentialMerger.merge(
                raw: current.raw,
                accessToken: response.accessToken,
                refreshToken: response.refreshToken ?? refreshToken,
                expiresAt: expiresAt
            )
            try await writeCredentials(merged, to: current.source)
            return response.accessToken
        } catch OAuthClient.RefreshError.invalidGrant {
            deadRefreshToken = refreshToken
            error = L("error.login_required")
            return nil
        } catch {
            self.error = L("error.token_refresh_failed")
            return nil
        }
    }

    // MARK: - Credential I/O

    /// `security` süreci ana iş parçacığını kilitlemesin diye okuma arka planda yapılır
    private func readCredentials() async -> CredentialStore.Snapshot? {
        let store = self.store
        return await Task.detached(priority: .userInitiated) { store.read() }.value
    }

    /// Yazma, Claude Code'un depo kilidi altında yapılır; kilit alınamazsa yazılmaz,
    /// çünkü yarım kalmış bir Claude Code yazmasının üzerine binmek kaydı bozabilir.
    private func writeCredentials(_ raw: Data, to source: CredentialStore.Source) async throws {
        let lock = DirectoryLock(path: store.storageLockPath)
        let locked = await lock.acquire(retries: 10, minDelay: 0.1, maxDelay: 1.0)
        guard locked else { throw CredentialStore.StoreError.fileWriteFailed("storage lock busy") }
        defer { lock.release() }

        let store = self.store
        try await Task.detached(priority: .userInitiated) { try store.write(raw, to: source) }.value
    }

    // MARK: - Polling

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshInterval), repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    private func restartPolling() {
        timer?.invalidate()
        startPolling()
    }

    // MARK: - Notifications

    func sendTestNotification() {
        let resetTime = L("time.hours_minutes", 2, 34)

        notifier.send(title: L("notification.50_title"), body: L("notification.test_50_body"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.notifier.send(title: L("notification.75_title"), body: L("notification.test_75_body"))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.notifier.send(title: L("notification.limit_title"), body: L("notification.test_limit_body", resetTime))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
            self?.notifier.send(title: L("notification.reset_title"), body: L("notification.test_reset_body"))
        }
    }

    /// İzlenen her kova için önceki durumla karşılaştırıp bildirim üretir.
    /// Kova anahtarı API alan adıdır; model bazlı kovalar model adıyla anahtarlanır.
    private func notifyThresholds(for new: UsageResponse) {
        let settings = ThresholdSettings(at50: notifyAt50, at75: notifyAt75, at100: notifyAt100, onReset: notifyOnReset)

        var tracked: [(key: String, name: String, bucket: UsageBucket)] = []
        if let bucket = new.fiveHour, bucket.hasData {
            tracked.append(("five_hour", L("limit.current_session"), bucket))
        }
        if let bucket = new.sevenDay, bucket.hasData {
            tracked.append(("seven_day", L("limit.weekly"), bucket))
        }
        if let bucket = new.sevenDaySonnet, bucket.hasData {
            tracked.append(("seven_day_sonnet", L("limit.sonnet_weekly"), bucket))
        }
        if let bucket = new.sevenDayOpus, bucket.hasData {
            tracked.append(("seven_day_opus", L("limit.opus_weekly"), bucket))
        }
        for limit in new.modelLimits {
            guard let name = limit.modelName else { continue }
            tracked.append(("model:\(name.lowercased())", L("limit.model_weekly", name), limit.bucket))
        }
        if let extra = new.extraUsage, extra.isEnabled {
            let bucket = UsageBucket(utilization: Double(extra.percent), resetsAt: nil)
            tracked.append(("extra_usage", L("limit.extra_usage"), bucket))
        }

        var next: [String: BucketSnapshot] = [:]
        for item in tracked {
            let snapshot = BucketSnapshot(percent: item.bucket.percent, resetsAt: item.bucket.resetsAt)
            let events = UsageThresholds.events(previous: previous[item.key], current: snapshot, settings: settings)
            for event in events {
                deliver(event, limitName: item.name, bucket: item.bucket)
            }
            next[item.key] = snapshot
        }
        previous = next
    }

    private func deliver(_ event: UsageEvent, limitName: String, bucket: UsageBucket) {
        switch event {
        case .reached50:
            notifier.send(title: L("notification.50_title"), body: L("notification.50_body", limitName))
        case .reached75:
            notifier.send(title: L("notification.75_title"), body: L("notification.75_body", limitName))
        case .limitReached:
            let body: String
            if let remaining = bucket.remainingText() {
                body = L("notification.limit_body_resets", limitName, remaining)
            } else {
                body = L("notification.limit_body", limitName)
            }
            notifier.send(title: L("notification.limit_title"), body: body)
        case .reset:
            notifier.send(title: L("notification.reset_title"), body: L("notification.reset_body", limitName))
        }
    }
}
