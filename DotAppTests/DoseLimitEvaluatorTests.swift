import XCTest
@testable import dot

final class DoseLimitEvaluatorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testRollingWindowIncludesExactLowerBoundaryAndNow() {
        let result = DoseLimitEvaluator.assess(
            timestamps: [
                now.addingTimeInterval(-DoseLimitEvaluator.rollingWindow),
                now,
                now.addingTimeInterval(-DoseLimitEvaluator.rollingWindow - 1),
                now.addingTimeInterval(1)
            ],
            configuration: .init(maximumDosesPerRolling24Hours: 3, minimumGapHours: 4),
            now: now
        )

        XCTAssertEqual(result.dosesInRolling24Hours, 2)
        XCTAssertFalse(result.maximumReached)
    }

    func testMaximumIsReachedAtConfiguredCount() {
        let result = DoseLimitEvaluator.assess(
            timestamps: [now.addingTimeInterval(-100), now.addingTimeInterval(-200)],
            configuration: .init(maximumDosesPerRolling24Hours: 2, minimumGapHours: 1),
            now: now
        )

        XCTAssertTrue(result.maximumReached)
    }

    func testRemainingGapUsesLatestEligibleDose() {
        let result = DoseLimitEvaluator.assess(
            timestamps: [now.addingTimeInterval(-3_600), now.addingTimeInterval(-7_200)],
            configuration: .init(maximumDosesPerRolling24Hours: 4, minimumGapHours: 4),
            now: now
        )

        XCTAssertEqual(try XCTUnwrap(result.remainingGap), 3 * 3_600, accuracy: 0.001)
        XCTAssertTrue(result.shouldWait)
    }

    func testInvalidConfigurationFailsClosedWithoutInventingStatus() {
        let result = DoseLimitEvaluator.assess(
            timestamps: [now],
            configuration: .init(maximumDosesPerRolling24Hours: 0, minimumGapHours: .nan),
            now: now
        )

        XCTAssertFalse(result.configurationIsValid)
        XCTAssertFalse(result.maximumReached)
        XCTAssertNil(result.remainingGap)
    }
}
