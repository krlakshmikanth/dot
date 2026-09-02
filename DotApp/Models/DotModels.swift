import Foundation
import SwiftData

@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarInitial: String
    var age: Int?
    var medicalID: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        avatarInitial: String,
        age: Int? = nil,
        medicalID: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.avatarInitial = avatarInitial
        self.age = age
        self.medicalID = medicalID
        self.createdAt = createdAt
    }

    var displayInitial: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .first
            .map { String($0).uppercased() } ?? "?"
    }
}

@Model
final class Medication {
    @Attribute(.unique) var id: UUID
    var profileID: UUID
    var name: String
    var doseAmount: Double
    var doseUnit: String
    var maximumDosesPerRolling24Hours: Int
    var minimumGapHours: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        profileID: UUID,
        name: String,
        doseAmount: Double,
        doseUnit: String,
        maximumDosesPerRolling24Hours: Int,
        minimumGapHours: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.profileID = profileID
        self.name = name
        self.doseAmount = doseAmount
        self.doseUnit = doseUnit
        self.maximumDosesPerRolling24Hours = maximumDosesPerRolling24Hours
        self.minimumGapHours = minimumGapHours
        self.createdAt = createdAt
    }

    var displayDose: String {
        "\(doseAmount.formatted(.number.precision(.fractionLength(0...2)))) \(doseUnit)"
    }
}

@Model
final class DoseLog {
    @Attribute(.unique) var id: UUID
    var medicationID: UUID
    var timestamp: Date

    init(id: UUID = UUID(), medicationID: UUID, timestamp: Date = .now) {
        self.id = id
        self.medicationID = medicationID
        self.timestamp = timestamp
    }
}
