import Foundation

/// Fetches Claude usage limits from Anthropic API.
///
/// Handles OAuth token refresh automatically when tokens expire.
/// Updates are fetched on init and every 60 seconds thereafter.
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
    
    // MARK: - Previous Usage (for threshold detection)
    
    private var previousFiveHour: Int?
    private var previousSevenDay: Int?
    private var previousSevenDaySonnet: Int?
    private var previousExtraUsage: Int?
    
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
    
    // MARK: - Configuration
    
    private let usageURL = "https://api.anthropic.com/api/oauth/usage"
    private let tokenURL = "https://platform.claude.com/v1/oauth/token"
    private let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    private let keychainService = "Claude Code-credentials"
    
    private var timer: Timer?
    
    // MARK: - Lifecycle
    
    init() {
        let defaults = UserDefaults.standard
        showPercentage = defaults.object(forKey: "showPercentage") as? Bool ?? true
        refreshInterval = defaults.object(forKey: "refreshInterval") as? Int ?? 60
        notifyAt50 = defaults.object(forKey: "notifyAt50") as? Bool ?? true
        notifyAt75 = defaults.object(forKey: "notifyAt75") as? Bool ?? true
        notifyAt100 = defaults.object(forKey: "notifyAt100") as? Bool ?? true
        notifyOnReset = defaults.object(forKey: "notifyOnReset") as? Bool ?? false
        let langRaw = defaults.string(forKey: "appLanguage") ?? "system"
        appLanguage = AppLanguage(rawValue: langRaw) ?? .system
        
        Task { await refresh() }
        startPolling()
    }
    
    deinit {
        MainActor.assumeIsolated {
            timer?.invalidate()
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetches latest usage data from API
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        guard let credentials = readKeychain() else {
            error = L("error.not_logged_in")
            return
        }
        
        guard let token = credentials.claudeAiOauth?.accessToken else {
            error = L("error.no_access_token")
            return
        }
        
        planType = credentials.claudeAiOauth?.subscriptionType
        
        // Try request with current token
        switch await fetchUsage(token: token) {
        case .success(let data):
            parseUsage(data)
            
        case .unauthorized:
            // Token expired, try refresh
            await handleTokenRefresh(credentials: credentials)
            
        case .error(let message):
            error = message
        }
    }
    
    // MARK: - API Requests
    
    private enum APIResult {
        case success(Data)
        case unauthorized
        case error(String)
    }
    
    private func fetchUsage(token: String) async -> APIResult {
        guard let url = URL(string: usageURL) else {
            return .error(L("error.invalid_url"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            switch status {
            case 200: return .success(data)
            case 401: return .unauthorized
            default: return .error(L("error.http", status))
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }
    
    private func parseUsage(_ data: Data) {
        do {
            let newUsage = try JSONDecoder().decode(UsageResponse.self, from: data)
            checkAllThresholds(newUsage)
            usage = newUsage
            error = nil
            lastUpdate = Date()
        } catch {
            self.error = L("error.parse")
        }
    }
    
    // MARK: - Token Refresh
    
    private func handleTokenRefresh(credentials: KeychainCredentials) async {
        guard let refreshToken = credentials.claudeAiOauth?.refreshToken else {
            error = L("error.no_refresh_token")
            return
        }
        
        guard let newToken = await refreshAccessToken(refreshToken, credentials: credentials) else {
            error = L("error.token_refresh_failed")
            return
        }
        
        // Retry with new token
        if case .success(let data) = await fetchUsage(token: newToken) {
            parseUsage(data)
        } else {
            error = L("error.request_failed")
        }
    }
    
    private func refreshAccessToken(_ refreshToken: String, credentials: KeychainCredentials) async -> String? {
        guard let url = URL(string: tokenURL) else { return nil }
        
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID,
            "scope": "user:inference user:profile user:sessions:claude_code"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            
            let tokenResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
            
            // Save new tokens to keychain
            saveTokens(
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken ?? refreshToken,
                expiresIn: tokenResponse.expiresIn ?? 3600,
                original: credentials
            )
            
            return tokenResponse.accessToken
        } catch {
            return nil
        }
    }
    
    // MARK: - Keychain
    
    private func readKeychain() -> KeychainCredentials? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", keychainService, "-w"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else { return nil }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let json = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !json.isEmpty else { return nil }
            
            return try JSONDecoder().decode(KeychainCredentials.self, from: Data(json.utf8))
        } catch {
            return nil
        }
    }
    
    private func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int, original: KeychainCredentials) {
        guard let oauth = original.claudeAiOauth else { return }
        
        let expiresAt = Date().timeIntervalSince1970 * 1000 + Double(expiresIn) * 1000
        
        let updated = KeychainCredentials(
            claudeAiOauth: KeychainCredentials.OAuthCredentials(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                scopes: oauth.scopes,
                subscriptionType: oauth.subscriptionType,
                rateLimitTier: oauth.rateLimitTier
            )
        )
        
        guard let jsonData = try? JSONEncoder().encode(updated),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        // Delete old entry
        let delete = Process()
        delete.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        delete.arguments = ["delete-generic-password", "-s", keychainService]
        delete.standardOutput = Pipe()
        delete.standardError = Pipe()
        try? delete.run()
        delete.waitUntilExit()
        
        // Add new entry
        let add = Process()
        add.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        add.arguments = ["add-generic-password", "-a", NSUserName(), "-s", keychainService, "-w", jsonString]
        add.standardOutput = Pipe()
        add.standardError = Pipe()
        try? add.run()
        add.waitUntilExit()
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
        let resetTime = formatResetTime(hours: 2, minutes: 34)
        
        sendNotification(title: L("notification.50_title"), body: L("notification.test_50_body"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.sendNotification(title: L("notification.75_title"), body: L("notification.test_75_body"))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.sendNotification(title: L("notification.limit_title"), body: L("notification.test_limit_body", resetTime))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
            self?.sendNotification(title: L("notification.reset_title"), body: L("notification.test_reset_body"))
        }
    }
    
    private func formatResetTime(hours: Int, minutes: Int) -> String {
        if hours > 0 {
            return L("time.hours_minutes", hours, minutes)
        }
        return L("time.minutes", minutes)
    }
    
    private func getResetTimeFromBucket(_ bucket: UsageBucket?) -> String? {
        guard let bucket = bucket, let resetDate = bucket.resetDate else { return nil }
        let seconds = resetDate.timeIntervalSince(Date())
        guard seconds > 0 else { return nil }
        
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return formatResetTime(hours: hours, minutes: minutes)
    }
    
    private func checkThresholds(oldValue: Int?, newValue: Int, limitName: String, resetTime: String?) {
        guard let old = oldValue else { return }
        
        if notifyAt50 && old < 50 && newValue >= 50 {
            sendNotification(
                title: L("notification.50_title"),
                body: L("notification.50_body", limitName)
            )
        }
        
        if notifyAt75 && old < 75 && newValue >= 75 {
            sendNotification(
                title: L("notification.75_title"),
                body: L("notification.75_body", limitName)
            )
        }
        
        if notifyAt100 && old < 100 && newValue >= 100 {
            let body: String
            if let time = resetTime {
                body = L("notification.limit_body_resets", limitName, time)
            } else {
                body = L("notification.limit_body", limitName)
            }
            sendNotification(title: L("notification.limit_title"), body: body)
        }
        
        if notifyOnReset && old > 0 && newValue == 0 {
            sendNotification(
                title: L("notification.reset_title"),
                body: L("notification.reset_body", limitName)
            )
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let escapedTitle = title.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        
        let script = """
            display notification "\(escapedBody)" with title "\(escapedTitle)" sound name "default"
            """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
    
    private func checkAllThresholds(_ newUsage: UsageResponse) {
        if let bucket = newUsage.fiveHour {
            let resetTime = getResetTimeFromBucket(bucket)
            checkThresholds(oldValue: previousFiveHour, newValue: bucket.percent, limitName: L("limit.current_session"), resetTime: resetTime)
            previousFiveHour = bucket.percent
        }
        
        if let bucket = newUsage.sevenDay {
            let resetTime = getResetTimeFromBucket(bucket)
            checkThresholds(oldValue: previousSevenDay, newValue: bucket.percent, limitName: L("limit.weekly"), resetTime: resetTime)
            previousSevenDay = bucket.percent
        }
        
        if let bucket = newUsage.sevenDaySonnet {
            let resetTime = getResetTimeFromBucket(bucket)
            checkThresholds(oldValue: previousSevenDaySonnet, newValue: bucket.percent, limitName: L("limit.sonnet_weekly"), resetTime: resetTime)
            previousSevenDaySonnet = bucket.percent
        }
        
        if let extra = newUsage.extraUsage, extra.isEnabled {
            checkThresholds(oldValue: previousExtraUsage, newValue: extra.percent, limitName: L("limit.extra_usage"), resetTime: nil)
            previousExtraUsage = extra.percent
        }
    }
}
