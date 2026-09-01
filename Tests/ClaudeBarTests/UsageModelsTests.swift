import XCTest
@testable import ClaudeBar

final class UsageModelsTests: XCTestCase {

    /// Claude Code 2.1.257'nin beklediği şemanın tamamını içeren örnek yanıt
    private let fullResponse = """
    {
      "five_hour": { "utilization": 11.4, "resets_at": "2026-09-01T21:00:00Z" },
      "seven_day": { "utilization": 42.6, "resets_at": "2026-09-05T07:00:00.000000+00:00" },
      "seven_day_sonnet": { "utilization": null, "resets_at": null },
      "seven_day_opus": null,
      "seven_day_oauth_apps": { "utilization": 0, "resets_at": null },
      "cinder_cove": { "utilization": 30, "resets_at": "2026-10-01T00:00:00Z" },
      "extra_usage": {
        "is_enabled": true, "monthly_limit": 5000, "used_credits": 1234.5,
        "utilization": 24.69, "currency": "USD", "disabled_reason": null
      },
      "limits": [
        { "kind": "weekly_scoped", "group": "model", "percent": 17.2, "resets_at": "2026-09-05T07:00:00Z",
          "scope": { "model": { "display_name": "Fable" } } },
        { "kind": "weekly_scoped", "group": "surface", "percent": 5, "resets_at": null,
          "scope": { "surface": { "display_name": "Claude Code" } } },
        { "kind": "session_scoped", "group": "model", "percent": 99, "resets_at": null,
          "scope": { "model": { "display_name": "Sonnet" } } }
      ],
      "some_future_field": { "anything": true }
    }
    """

    func testDecodesFullSchema() throws {
        let usage = try JSONDecoder().decode(UsageResponse.self, from: Data(fullResponse.utf8))

        XCTAssertEqual(usage.fiveHour?.percent, 11)
        XCTAssertEqual(usage.sevenDay?.percent, 43)
        XCTAssertEqual(usage.sevenDaySonnet?.hasData, false)
        XCTAssertNil(usage.sevenDayOpus)
        XCTAssertEqual(usage.sevenDayOAuthApps?.percent, 0)
        XCTAssertEqual(usage.oneTimeCredit?.percent, 30)
        XCTAssertEqual(usage.extraUsage?.percent, 25)
        XCTAssertEqual(usage.extraUsage?.currency, "USD")
    }

    func testModelLimitsKeepOnlyWeeklyModelScoped() throws {
        let usage = try JSONDecoder().decode(UsageResponse.self, from: Data(fullResponse.utf8))
        let names = usage.modelLimits.map(\.modelName)
        XCTAssertEqual(names, ["Fable"])
        XCTAssertEqual(usage.modelLimits.first?.bucket.percent, 17)
    }

    func testMinimalLegacyResponseStillDecodes() throws {
        // v1.0 zamanındaki yanıt biçimi: limits ve cinder_cove yok
        let legacy = """
        { "five_hour": { "utilization": 5.0, "resets_at": "2026-02-06T11:00:00Z" },
          "seven_day": { "utilization": 42.0, "resets_at": "2026-02-07T07:00:00Z" } }
        """
        let usage = try JSONDecoder().decode(UsageResponse.self, from: Data(legacy.utf8))
        XCTAssertEqual(usage.fiveHour?.percent, 5)
        XCTAssertTrue(usage.modelLimits.isEmpty)
        XCTAssertNil(usage.extraUsage)
    }

    func testResetDateParsesBothISOForms() {
        XCTAssertNotNil(UsageBucket(utilization: 1, resetsAt: "2026-09-01T21:00:00Z").resetDate)
        XCTAssertNotNil(UsageBucket(utilization: 1, resetsAt: "2026-09-01T21:00:00.123Z").resetDate)
        XCTAssertNotNil(UsageBucket(utilization: 1, resetsAt: "2026-09-05T07:00:00.000000+00:00").resetDate)
        XCTAssertNil(UsageBucket(utilization: 1, resetsAt: "yarın").resetDate)
        XCTAssertNil(UsageBucket(utilization: 1, resetsAt: nil).resetDate)
    }

    func testResetTextIsNilOncePassed() {
        let past = UsageBucket(utilization: 50, resetsAt: "2020-01-01T00:00:00Z")
        XCTAssertNil(past.resetText(style: .relative))
        XCTAssertNil(past.remainingText())
    }

    func testExtraUsageVisibleWhenDisabledWithReason() throws {
        let json = """
        { "is_enabled": false, "monthly_limit": null, "used_credits": null,
          "utilization": null, "disabled_reason": "out_of_credits" }
        """
        let extra = try JSONDecoder().decode(ExtraUsage.self, from: Data(json.utf8))
        XCTAssertTrue(extra.isVisible)
        XCTAssertEqual(extra.percent, 0)
        XCTAssertNotNil(extra.disabledReasonText)
    }

    func testExtraUsagePercentFallsBackToRatio() throws {
        let json = """
        { "is_enabled": true, "monthly_limit": 2000, "used_credits": 500, "utilization": null }
        """
        let extra = try JSONDecoder().decode(ExtraUsage.self, from: Data(json.utf8))
        XCTAssertEqual(extra.percent, 25)
    }

    func testPlanBadgePrefersTierMultiplier() {
        XCTAssertEqual(PlanBadge.text(subscriptionType: "max", rateLimitTier: "default_claude_max_5x"), "Max 5x")
        XCTAssertEqual(PlanBadge.text(subscriptionType: "max", rateLimitTier: "default_claude_max_20x"), "Max 20x")
        XCTAssertEqual(PlanBadge.text(subscriptionType: "pro", rateLimitTier: "default_claude_ai"), "Pro")
        XCTAssertEqual(PlanBadge.text(subscriptionType: "claude_team", rateLimitTier: nil), "Team")
        XCTAssertNil(PlanBadge.text(subscriptionType: nil, rateLimitTier: nil))
    }

    func testExpiringSoonUsesFiveMinuteLeeway() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        func creds(expiresInSeconds: Double) -> KeychainCredentials.OAuthCredentials {
            KeychainCredentials.OAuthCredentials(
                accessToken: "a", refreshToken: "r",
                expiresAt: (now.timeIntervalSince1970 + expiresInSeconds) * 1000,
                scopes: nil, subscriptionType: nil, rateLimitTier: nil
            )
        }
        XCTAssertTrue(creds(expiresInSeconds: 120).isExpiringSoon(now: now))
        XCTAssertFalse(creds(expiresInSeconds: 600).isExpiringSoon(now: now))
        XCTAssertFalse(KeychainCredentials.OAuthCredentials(
            accessToken: "a", refreshToken: nil, expiresAt: nil,
            scopes: nil, subscriptionType: nil, rateLimitTier: nil
        ).isExpiringSoon(now: now))
    }
}
