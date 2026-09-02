import XCTest

final class DotFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddMedicineLogDoseAndOpenStatus() {
        let app = XCUIApplication()
        app.launchArguments = ["-dot-ui-testing"]
        app.launch()

        let logDose = app.buttons["Log a dose"]
        XCTAssertTrue(logDose.waitForExistence(timeout: 5))
        logDose.tap()

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
        medication.tap()

        let logNow = app.buttons["log-dose-now"]
        XCTAssertTrue(logNow.isEnabled)
        logNow.tap()

        XCTAssertTrue(app.staticTexts["Dose logged"].waitForExistence(timeout: 3))
        app.buttons["view-status"].tap()

        XCTAssertTrue(app.staticTexts["Status"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Me"].exists)
        let rollingWindowHeading = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "rolling 24 hours"))
            .firstMatch
        XCTAssertTrue(rollingWindowHeading.exists)
        XCTAssertTrue(app.staticTexts["Metformin"].exists)
    }

    func testCreateAndSwitchProfiles() {
        let app = XCUIApplication()
        app.launchArguments = ["-dot-ui-testing"]
        app.launch()

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

    private func replaceText(in field: XCUIElement, with value: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText(value)
    }
}
