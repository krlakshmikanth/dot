import Foundation

struct DoseConfiguration: Equatable, Sendable {
    let maximumDosesPerRolling24Hours: Int
    let minimumGapHours: Double

    var isValid: Bool {
        maximumDosesPerRolling24Hours > 0
            && minimumGapHours.isFinite
            && minimumGapHours > 0
    }
}

struct DoseLimitAssessment: Equatable, Sendable {
    let dosesInRolling24Hours: Int
    let maximumReached: Bool
    let remainingGap: TimeInterval?
    let configurationIsValid: Bool

    var shouldWait: Bool {
        guard let remainingGap else { return false }
        return remainingGap > 0
    }
}

enum DoseLimitEvaluator {
    static let rollingWindow: TimeInterval = 24 * 60 * 60

    static func assess(
        timestamps: [Date],
        configuration: DoseConfiguration,
        now: Date
    ) -> DoseLimitAssessment {
        guard configuration.isValid else {
            return DoseLimitAssessment(
                dosesInRolling24Hours: 0,
                maximumReached: false,
                remainingGap: nil,
                configurationIsValid: false
            )
        }

        let lowerBound = now.addingTimeInterval(-rollingWindow)
        let eligible = timestamps.filter { timestamp in
            timestamp >= lowerBound && timestamp <= now
        }
        let latest = eligible.max()
        let minimumGap = configuration.minimumGapHours * 60 * 60
        let remainingGap = latest.map { max(0, minimumGap - now.timeIntervalSince($0)) }

        return DoseLimitAssessment(
            dosesInRolling24Hours: eligible.count,
            maximumReached: eligible.count >= configuration.maximumDosesPerRolling24Hours,
            remainingGap: remainingGap,
            configurationIsValid: true
        )
    }
}
