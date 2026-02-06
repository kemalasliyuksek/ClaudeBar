import Foundation

/// Fetches Claude usage limits from Anthropic API.
///
/// Handles OAuth token refresh automatically when tokens expire.
/// Updates are fetched on init and every 60 seconds thereafter.
@Observable
final class UsageService {
    
    // MARK: - Public State
    
    private(set) var usage: UsageResponse?
    private(set) var error: String?
    private(set) var lastUpdate: Date?
    private(set) var isLoading = false
    private(set) var planType: String?
    
    // MARK: - Previous Usage (for threshold detection)
    
    private var previousFiveHour: Int?
    private var previousSevenDay: Int?
    private var previousSevenDaySonnet: Int?
    private var previousExtraUsage: Int?
    
    // MARK: - Settings (persisted)
    
    var showPercentage: Bool {
        get { UserDefaults.standard.object(forKey: "showPercentage") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showPercentage") }
    }
    
    var refreshInterval: Int {
        get { UserDefaults.standard.object(forKey: "refreshInterval") as? Int ?? 60 }
        set {
            UserDefaults.standard.set(newValue, forKey: "refreshInterval")
            restartPolling()
        }
    }
    
    // MARK: - Notification Settings (persisted)
    
    var notifyAt50: Bool {
        get { UserDefaults.standard.object(forKey: "notifyAt50") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyAt50") }
    }
    
    var notifyAt75: Bool {
        get { UserDefaults.standard.object(forKey: "notifyAt75") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyAt75") }
    }
    
    var notifyAt100: Bool {
        get { UserDefaults.standard.object(forKey: "notifyAt100") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyAt100") }
    }
    
    var notifyOnReset: Bool {
        get { UserDefaults.standard.object(forKey: "notifyOnReset") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "notifyOnReset") }
    }
    
    // MARK: - Configuration
    
    private let usageURL = "https://api.anthropic.com/api/oauth/usage"
    private let tokenURL = "https://platform.claude.com/v1/oauth/token"
    private let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    private let keychainService = "Claude Code-credentials"
    
    private var timer: Timer?
    
    // MARK: - Lifecycle
    
    init() {
        Task { await refresh() }
        startPolling()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Fetches latest usage data from API
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        guard let credentials = readKeychain() else {
            error = "Not logged in"
            return
        }
        
        guard let token = credentials.claudeAiOauth?.accessToken else {
            error = "No access token"
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
            return .error("Invalid URL")
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
            default: return .error("HTTP \(status)")
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
            self.error = "Parse error"
        }
    }
    
    // MARK: - Token Refresh
    
    private func handleTokenRefresh(credentials: KeychainCredentials) async {
        guard let refreshToken = credentials.claudeAiOauth?.refreshToken else {
            error = "No refresh token"
            return
        }
        
        guard let newToken = await refreshAccessToken(refreshToken, credentials: credentials) else {
            error = "Token refresh failed"
            return
        }
        
        // Retry with new token
        if case .success(let data) = await fetchUsage(token: newToken) {
            parseUsage(data)
        } else {
            error = "Request failed"
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
        
        // Send all notification types with delays
        sendNotification(title: "50% Usage Warning", body: "You've used 50% of your current session limit.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
            sendNotification(title: "75% Usage Warning", body: "You've used 75% of your current session limit.")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
            sendNotification(title: "Limit Reached", body: "You've reached your current session limit. Resets in \(resetTime).")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [self] in
            sendNotification(title: "Limit Reset", body: "Your current session limit has been reset. You can continue using Claude.")
        }
    }
    
    private func formatResetTime(hours: Int, minutes: Int) -> String {
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
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
        
        // Check 50% threshold
        if notifyAt50 && old < 50 && newValue >= 50 {
            sendNotification(
                title: "50% Usage Warning",
                body: "You've used 50% of your \(limitName.lowercased())."
            )
        }
        
        // Check 75% threshold
        if notifyAt75 && old < 75 && newValue >= 75 {
            sendNotification(
                title: "75% Usage Warning",
                body: "You've used 75% of your \(limitName.lowercased())."
            )
        }
        
        // Check 100% threshold with reset time
        if notifyAt100 && old < 100 && newValue >= 100 {
            var body = "You've reached your \(limitName.lowercased())."
            if let time = resetTime {
                body += " Resets in \(time)."
            }
            sendNotification(title: "Limit Reached", body: body)
        }
        
        // Check for reset
        if notifyOnReset && old > 0 && newValue == 0 {
            sendNotification(
                title: "Limit Reset",
                body: "Your \(limitName.lowercased()) has been reset. You can continue using Claude."
            )
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let script = """
            display notification "\(body)" with title "\(title)" sound name "default"
            """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
    
    private func checkAllThresholds(_ newUsage: UsageResponse) {
        if let bucket = newUsage.fiveHour {
            let resetTime = getResetTimeFromBucket(bucket)
            checkThresholds(oldValue: previousFiveHour, newValue: bucket.percent, limitName: "Current Session", resetTime: resetTime)
            previousFiveHour = bucket.percent
        }
        
        if let bucket = newUsage.sevenDay {
            let resetTime = getResetTimeFromBucket(bucket)
            checkThresholds(oldValue: previousSevenDay, newValue: bucket.percent, limitName: "Weekly Limit", resetTime: resetTime)
            previousSevenDay = bucket.percent
        }
        
        if let bucket = newUsage.sevenDaySonnet {
            let resetTime = getResetTimeFromBucket(bucket)
            checkThresholds(oldValue: previousSevenDaySonnet, newValue: bucket.percent, limitName: "Sonnet Weekly", resetTime: resetTime)
            previousSevenDaySonnet = bucket.percent
        }
        
        if let extra = newUsage.extraUsage, extra.isEnabled {
            checkThresholds(oldValue: previousExtraUsage, newValue: extra.percent, limitName: "Extra Usage", resetTime: nil)
            previousExtraUsage = extra.percent
        }
    }
}
