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
            usage = try JSONDecoder().decode(UsageResponse.self, from: data)
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
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }
}
