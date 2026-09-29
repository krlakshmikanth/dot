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
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        profileID: UUID,
        name: String,
        doseAmount: Double,
        doseUnit: String,
        maximumDosesPerRolling24Hours: Int,
        minimumGapHours: Double,
        createdAt: Date = .now,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.profileID = profileID
        self.name = name
        self.doseAmount = doseAmount
        self.doseUnit = doseUnit
        self.maximumDosesPerRolling24Hours = maximumDosesPerRolling24Hours
        self.minimumGapHours = minimumGapHours
        self.createdAt = createdAt
        self.archivedAt = archivedAt
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
    var recordedMedicationName: String?
    var recordedDoseAmount: Double?
    var recordedDoseUnit: String?
    var confirmationState: String?
    var correctedAt: Date?

    init(
        id: UUID = UUID(),
        medicationID: UUID,
        timestamp: Date = .now,
        medicationName: String? = nil,
        doseAmount: Double? = nil,
        doseUnit: String? = nil,
        isUncertain: Bool = false,
        correctedAt: Date? = nil
    ) {
        self.id = id
        self.medicationID = medicationID
        self.timestamp = timestamp
        self.recordedMedicationName = medicationName
        self.recordedDoseAmount = doseAmount
        self.recordedDoseUnit = doseUnit
        self.confirmationState = isUncertain ? "uncertain" : "confirmed"
        self.correctedAt = correctedAt
    }

    var isUncertain: Bool {
        confirmationState == "uncertain"
    }

    func displayName(fallback medication: Medication?) -> String {
        recordedMedicationName ?? medication?.name ?? "Archived medicine"
    }

    func displayDose(fallback medication: Medication?) -> String {
        let amount = recordedDoseAmount ?? medication?.doseAmount
        let unit = recordedDoseUnit ?? medication?.doseUnit
        guard let amount, let unit else { return "Dose not recorded" }
        return "\(amount.formatted(.number.precision(.fractionLength(0...2)))) \(unit)"
    }
}

@Model
final class PlannedDose {
    @Attribute(.unique) var id: UUID
    var profileID: UUID
    var medicationID: UUID
    var medicationName: String
    var doseAmount: Double
    var doseUnit: String
    var plannedAt: Date

    init(
        id: UUID = UUID(),
        profileID: UUID,
        medicationID: UUID,
        medicationName: String,
        doseAmount: Double,
        doseUnit: String,
        plannedAt: Date = .now
    ) {
        self.id = id
        self.profileID = profileID
        self.medicationID = medicationID
        self.medicationName = medicationName
        self.doseAmount = doseAmount
        self.doseUnit = doseUnit
        self.plannedAt = plannedAt
    }

    var displayDose: String {
        "\(doseAmount.formatted(.number.precision(.fractionLength(0...2)))) \(doseUnit)"
    }
}
