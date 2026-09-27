import XCTest

/// End-to-end smoke tests: the real app, driven through accessibility like a player would.
final class SmokeTests: XCTestCase {
    @MainActor private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingReset"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["cell.e4"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor func testPlayingAMoveShowsItInTheMoveList() {
        let app = launch()
        app.descendants(matching: .any)["cell.e4"].tap()
        app.descendants(matching: .any)["cell.e6"].tap()
        XCTAssertTrue(app.staticTexts["1. e4-e6"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Black to move"].exists)
        let shot = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        shot.name = "after-e4-e6"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor func testResigningShowsTheResult() {
        let app = launch()
        app.buttons["Resign"].firstMatch.tap()
        app.buttons["Resign this game?"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["White resigns — Black wins"].firstMatch.waitForExistence(timeout: 5))
    }
}
