import Foundation

enum DoseUnit: String, CaseIterable, Identifiable {
    case milligrams = "mg"
    case millilitres = "ml"
    case tablet = "tab"

    var id: String { rawValue }
}

struct MedicationDraft: Equatable {
    var name = ""
    var doseAmount = ""
    var unit: DoseUnit = .milligrams
    var maximumDoses = ""
    var minimumGapHours = ""

    init(
        name: String = "",
        doseAmount: String = "",
        unit: DoseUnit = .milligrams,
        maximumDoses: String = "",
        minimumGapHours: String = ""
    ) {
        self.name = name
        self.doseAmount = doseAmount
        self.unit = unit
        self.maximumDoses = maximumDoses
        self.minimumGapHours = minimumGapHours
    }

    init(medication: Medication) {
        name = medication.name
        doseAmount = medication.doseAmount.formatted(.number.precision(.fractionLength(0...2)))
        unit = DoseUnit(rawValue: medication.doseUnit) ?? .milligrams
        maximumDoses = String(medication.maximumDosesPerRolling24Hours)
        minimumGapHours = medication.minimumGapHours.formatted(.number.precision(.fractionLength(0...2)))
    }

    var validatedValues: ValidatedMedication? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty,
              let amount = Double(doseAmount),
              amount.isFinite,
              amount > 0,
              let maximum = Int(maximumDoses),
              maximum > 0,
              let gap = Double(minimumGapHours),
              gap.isFinite,
              gap > 0 else {
            return nil
        }

        return ValidatedMedication(
            name: cleanName,
            doseAmount: amount,
            unit: unit.rawValue,
            maximumDoses: maximum,
            minimumGapHours: gap
        )
    }
}

struct ValidatedMedication: Equatable {
    let name: String
    let doseAmount: Double
    let unit: String
    let maximumDoses: Int
    let minimumGapHours: Double
}

struct ProfileDraft: Equatable {
    var nickname = ""
    var age = ""
    var medicalID = ""

    init(nickname: String = "", age: String = "", medicalID: String = "") {
        self.nickname = nickname
        self.age = age
        self.medicalID = medicalID
    }

    init(profile: Profile) {
        nickname = profile.name
        age = profile.age.map(String.init) ?? ""
        medicalID = profile.medicalID ?? ""
    }

    var validatedValues: ValidatedProfile? {
        let cleanNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMedicalID = medicalID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNickname.isEmpty,
              cleanNickname.count <= 24,
              let parsedAge = Int(age),
              (1...130).contains(parsedAge) else {
            return nil
        }

        return ValidatedProfile(
            nickname: cleanNickname,
            age: parsedAge,
            medicalID: cleanMedicalID.isEmpty ? nil : cleanMedicalID
        )
    }
}

struct ValidatedProfile: Equatable {
    let nickname: String
    let age: Int
    let medicalID: String?
}
