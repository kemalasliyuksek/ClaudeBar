import XCTest
@testable import ClaudeBar

final class CredentialMergerTests: XCTestCase {

    func testMergePreservesUnknownFields() throws {
        let original = """
        {
          "claudeAiOauth": {
            "accessToken": "old-access",
            "refreshToken": "old-refresh",
            "expiresAt": 1700000000000,
            "scopes": ["user:inference"],
            "subscriptionType": "max",
            "rateLimitTier": "default_claude_max_5x",
            "futureField": { "nested": [1, 2, 3] }
          },
          "anotherTopLevel": "keep me"
        }
        """
        let expires = Date(timeIntervalSince1970: 1_800_000_000)
        let merged = try CredentialMerger.merge(
            raw: Data(original.utf8),
            accessToken: "new-access",
            refreshToken: "new-refresh",
            expiresAt: expires
        )

        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: merged) as? [String: Any])
        let oauth = try XCTUnwrap(root["claudeAiOauth"] as? [String: Any])

        XCTAssertEqual(oauth["accessToken"] as? String, "new-access")
        XCTAssertEqual(oauth["refreshToken"] as? String, "new-refresh")
        XCTAssertEqual(oauth["expiresAt"] as? Int64, 1_800_000_000_000)
        XCTAssertEqual(oauth["subscriptionType"] as? String, "max")
        XCTAssertEqual(oauth["scopes"] as? [String], ["user:inference"])
        XCTAssertNotNil(oauth["futureField"])
        XCTAssertEqual(root["anotherTopLevel"] as? String, "keep me")

        // Yazılan çıktı Claude Code'un beklediği Codable yapıya hâlâ uyuyor
        let decoded = try JSONDecoder().decode(KeychainCredentials.self, from: merged)
        XCTAssertEqual(decoded.claudeAiOauth?.accessToken, "new-access")
    }

    func testMergeRejectsMissingOAuthSection() {
        let raw = Data("{\"somethingElse\": 1}".utf8)
        XCTAssertThrowsError(try CredentialMerger.merge(raw: raw, accessToken: "a", refreshToken: "r", expiresAt: Date()))
    }

    func testMergeRejectsNonObject() {
        XCTAssertThrowsError(try CredentialMerger.merge(raw: Data("[1,2]".utf8), accessToken: "a", refreshToken: "r", expiresAt: Date()))
    }
}
