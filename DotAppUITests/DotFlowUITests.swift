import XCTest

final class DotFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPlanConfirmDoseAndOpenHistory() {
        let app = XCUIApplication()
        app.launchArguments = ["-dot-ui-testing"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Your day,\nat a glance."].waitForExistence(timeout: 5))
        let planDose = app.buttons["plan-dose"]
        XCTAssertTrue(planDose.waitForExistence(timeout: 5))
        planDose.tap()

        let addMedication = app.buttons["add-medication-from-log"]
        XCTAssertTrue(addMedication.waitForExistence(timeout: 3))
        addMedication.tap()

        replaceText(in: app.textFields["medication-name"], with: "Metformin")
        replaceText(in: app.textFields["medication-dose"], with: "500")
        replaceText(in: app.textFields["medication-maximum"], with: "2")
        replaceText(in: app.textFields["medication-gap"], with: "8")

        let save = app.buttons["save-medication"]
        XCTAssertTrue(save.isEnabled)
        save.tap()

        let medication = app.staticTexts["Metformin"]
        XCTAssertTrue(medication.waitForExistence(timeout: 3))

        let createPlan = app.buttons["create-dose-plan"]
        XCTAssertTrue(createPlan.waitForExistence(timeout: 3))
        createPlan.tap()

        XCTAssertTrue(app.staticTexts["Is this dose taken?"].waitForExistence(timeout: 3))
        app.buttons["confirm-dose-taken"].tap()

        XCTAssertTrue(app.staticTexts["Dose recorded"].waitForExistence(timeout: 3))
        app.buttons["dose-recorded-done"].tap()

        XCTAssertTrue(app.staticTexts["1 confirmed dose"].waitForExistence(timeout: 3))
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Metformin"].exists)

        let historyRecord = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-dose-"))
            .firstMatch
        XCTAssertTrue(historyRecord.waitForExistence(timeout: 3))
        historyRecord.tap()
        XCTAssertTrue(app.datePickers["record-dose-time"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["save-dose-correction"].isEnabled)
        app.buttons["save-dose-correction"].tap()

        app.tabBars.buttons["Settings"].tap()
        let manageMedicines = app.buttons["manage-medicines"]
        XCTAssertTrue(manageMedicines.waitForExistence(timeout: 3))
        manageMedicines.tap()
        let editMedicine = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "edit-medicine-"))
            .firstMatch
        XCTAssertTrue(editMedicine.waitForExistence(timeout: 3))
        editMedicine.tap()
        XCTAssertTrue(app.textFields["medication-name"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.textFields["medication-name"].value as? String, "Metformin")
        XCTAssertTrue(app.buttons["save-medication"].isEnabled)
    }

    func testCreateAndSwitchProfiles() {
        let app = XCUIApplication()
        app.launchArguments = ["-dot-ui-testing"]
        app.launch()

        let switchToDark = app.buttons["Switch to dark appearance"]
        if switchToDark.waitForExistence(timeout: 3) {
            switchToDark.tap()
            XCTAssertTrue(app.buttons["Switch to light appearance"].waitForExistence(timeout: 3))
        } else {
            let switchToLight = app.buttons["Switch to light appearance"]
            XCTAssertTrue(switchToLight.waitForExistence(timeout: 3))
            switchToLight.tap()
            XCTAssertTrue(app.buttons["Switch to dark appearance"].waitForExistence(timeout: 3))
        }

        app.tabBars.buttons["Settings"].tap()
        XCTAssertFalse(app.staticTexts["Time format"].exists)
        let addProfile = app.buttons["add-profile"]
        XCTAssertTrue(addProfile.waitForExistence(timeout: 5))
        addProfile.tap()

        replaceText(in: app.textFields["profile-nickname"], with: "Sam")
        replaceText(in: app.textFields["profile-age"], with: "9")
        replaceText(in: app.textFields["profile-medical-id"], with: "MED-123")

        let save = app.buttons["save-profile"]
        XCTAssertTrue(save.isEnabled)
        save.tap()

        let profileMenu = app.buttons["active-profile-menu"]
        XCTAssertTrue(profileMenu.waitForExistence(timeout: 3))
        XCTAssertEqual(profileMenu.label, "Switch profile. Active profile Sam")

        profileMenu.tap()
        let switchToMe = app.buttons["switch-profile-Me"]
        XCTAssertTrue(switchToMe.waitForExistence(timeout: 3))
        switchToMe.tap()

        XCTAssertEqual(profileMenu.label, "Switch profile. Active profile Me")
        XCTAssertTrue(app.staticTexts["Sam"].exists)
    }

    func testPrimaryActionsAreAvailableInDarkMode() {
        let app = XCUIApplication()
        app.launchArguments = ["-dot-ui-testing"]
        app.launch()

        let switchToDark = app.buttons["Switch to dark appearance"]
        if switchToDark.waitForExistence(timeout: 3) {
            switchToDark.tap()
        }

        let planDose = app.buttons["plan-dose"]
        XCTAssertTrue(planDose.waitForExistence(timeout: 3))
        XCTAssertTrue(planDose.isHittable)

        app.tabBars.buttons["History"].tap()
        let addMedicine = app.buttons["Add a medicine"]
        XCTAssertTrue(addMedicine.waitForExistence(timeout: 3))
        XCTAssertTrue(addMedicine.isHittable)
    }

    private func replaceText(in field: XCUIElement, with value: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText(value)
    }
}
