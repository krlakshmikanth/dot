import XCTest
@testable import dot

final class MedicationDraftTests: XCTestCase {
    func testValidDraftTrimsNameAndParsesValues() {
        let draft = MedicationDraft(
            name: "  Metformin  ",
            doseAmount: "500",
            unit: .milligrams,
            maximumDoses: "2",
            minimumGapHours: "8"
        )

        XCTAssertEqual(
            draft.validatedValues,
            ValidatedMedication(
                name: "Metformin",
                doseAmount: 500,
                unit: "mg",
                maximumDoses: 2,
                minimumGapHours: 8
            )
        )
    }

    func testRejectsNonFiniteAndNonPositiveValues() {
        var draft = MedicationDraft(
            name: "Medicine",
            doseAmount: "nan",
            unit: .tablet,
            maximumDoses: "1",
            minimumGapHours: "4"
        )
        XCTAssertNil(draft.validatedValues)

        draft.doseAmount = "1"
        draft.minimumGapHours = "0"
        XCTAssertNil(draft.validatedValues)
    }

    func testProfileDraftRequiresShortNicknameAndValidAge() {
        let valid = ProfileDraft(nickname: "  Sam  ", age: "9", medicalID: "  MED-123  ")
        XCTAssertEqual(
            valid.validatedValues,
            ValidatedProfile(nickname: "Sam", age: 9, medicalID: "MED-123")
        )

        XCTAssertNil(ProfileDraft(nickname: "Sam", age: "0").validatedValues)
        XCTAssertNil(ProfileDraft(nickname: "Sam", age: "131").validatedValues)
        XCTAssertNil(ProfileDraft(nickname: "", age: "9").validatedValues)
    }

    func testProfileDraftTreatsBlankMedicalIDAsAbsent() {
        let draft = ProfileDraft(nickname: "Sam", age: "9", medicalID: "   ")
        XCTAssertEqual(
            draft.validatedValues,
            ValidatedProfile(nickname: "Sam", age: 9, medicalID: nil)
        )
    }
}
