import Foundation

/// Anthropic OAuth uç noktalarıyla konuşan ince istemci. Durum tutmaz.
///
/// Sabitler Claude Code 2.1.257 binary'sinden doğrulandı: client ID, token URL'si
/// (platform.claude.com), beta başlığı ve varsayılan scope listesi.
struct OAuthClient: Sendable {
    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    static let tokenURL = URL(string: "https://platform.claude.com/v1/oauth/token")!
    static let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    static let betaHeader = "oauth-2025-04-20"
    /// Claude Code'un birinci taraf oturumlar için istediği scope kümesi
    static let defaultScopes = ["user:profile", "user:inference", "user:sessions:claude_code", "user:mcp_servers"]

    enum FetchResult: Sendable {
        case success(Data)
        case unauthorized
        case failure(String)
    }

    enum RefreshError: Error, Equatable {
        /// Refresh token artık geçersiz; tek çare yeniden giriş
        case invalidGrant
        /// İstenen scope kümesi bu token için reddedildi
        case invalidScope
        case http(Int)
        case transport(String)
        case decode
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Kayıtlı scope'ları varsayılanlarla birleştirir, sıra korunur, tekrar yok
    static func mergedScopes(stored: [String]) -> [String] {
        var seen = Set<String>()
        return (defaultScopes + stored).filter { seen.insert($0).inserted }
    }

    func fetchUsage(token: String) async -> FetchResult {
        var request = URLRequest(url: Self.usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.betaHeader, forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch status {
            case 200: return .success(data)
            case 401: return .unauthorized
            default: return .failure(L("error.http", status))
            }
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    func refresh(refreshToken: String, scopes: [String]) async throws -> TokenRefreshResponse {
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": Self.clientID,
            "scope": scopes.joined(separator: " "),
        ]

        var request = URLRequest(url: Self.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        // Claude Code 30 saniye bekliyor; token uç noktası bazen yavaş yanıt veriyor
        request.timeoutInterval = 30

        let data: Data
        let status: Int
        do {
            let (received, response) = try await session.data(for: request)
            data = received
            status = (response as? HTTPURLResponse)?.statusCode ?? 0
        } catch {
            throw RefreshError.transport(error.localizedDescription)
        }

        guard status == 200 else {
            // OAuth hata gövdesi {"error":"invalid_grant"} biçiminde gelir; metin araması yeterli
            let text = String(decoding: data, as: UTF8.self)
            if text.contains("invalid_grant") { throw RefreshError.invalidGrant }
            if text.contains("invalid_scope") { throw RefreshError.invalidScope }
            throw RefreshError.http(status)
        }

        do {
            return try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
        } catch {
            throw RefreshError.decode
        }
    }
}
