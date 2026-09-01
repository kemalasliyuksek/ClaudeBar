import XCTest
@testable import ClaudeBar

final class UsageThresholdsTests: XCTestCase {

    private let all = ThresholdSettings(at50: true, at75: true, at100: true, onReset: true)

    private func snap(_ percent: Int, _ resetsAt: String? = nil) -> BucketSnapshot {
        BucketSnapshot(percent: percent, resetsAt: resetsAt)
    }

    func testNoEventsOnFirstObservation() {
        XCTAssertEqual(UsageThresholds.events(previous: nil, current: snap(99), settings: all), [])
    }

    func testCrossing50() {
        XCTAssertEqual(UsageThresholds.events(previous: snap(49), current: snap(50), settings: all), [.reached50])
        XCTAssertEqual(UsageThresholds.events(previous: snap(50), current: snap(60), settings: all), [])
    }

    func testJumpAcrossSeveralThresholdsReportsEach() {
        XCTAssertEqual(
            UsageThresholds.events(previous: snap(10), current: snap(100), settings: all),
            [.reached50, .reached75, .limitReached]
        )
    }

    func testDisabledSettingsSuppressEvents() {
        let none = ThresholdSettings(at50: false, at75: false, at100: false, onReset: false)
        XCTAssertEqual(UsageThresholds.events(previous: snap(0), current: snap(100), settings: none), [])
    }

    func testResetWhenUsageDropsToZero() {
        XCTAssertEqual(UsageThresholds.events(previous: snap(80), current: snap(0), settings: all), [.reset])
    }

    func testResetWhenWindowRolledButUserAlreadyUsedSome() {
        let before = snap(90, "2026-09-01T10:00:00Z")
        let after = snap(4, "2026-09-01T15:00:00Z")
        XCTAssertEqual(UsageThresholds.events(previous: before, current: after, settings: all), [.reset])
    }

    func testDecreaseWithoutNewWindowIsNotReset() {
        // Sunucu tarafında küçük düzeltmeler olabilir; pencere aynıysa sıfırlanma değildir
        let before = snap(90, "2026-09-01T10:00:00Z")
        let after = snap(85, "2026-09-01T10:00:00Z")
        XCTAssertEqual(UsageThresholds.events(previous: before, current: after, settings: all), [])
    }

    func testZeroToZeroIsNotReset() {
        XCTAssertEqual(UsageThresholds.events(previous: snap(0), current: snap(0), settings: all), [])
    }
}
