import XCTest
@testable import VoiceScribe

final class AppStateTests: XCTestCase {
    func testStatusTransitions() {
        let appState = AppState.shared
        let recordingExpectation = expectation(description: "Status updates to recording")
        let processingExpectation = expectation(description: "Status updates to processing")
        let idleExpectation = expectation(description: "Status updates to idle")

        appState.updateStatus(.recording)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(appState.status, .recording)
            recordingExpectation.fulfill()

            appState.updateStatus(.processing)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertEqual(appState.status, .processing)
                processingExpectation.fulfill()

                appState.updateStatus(.idle)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    XCTAssertEqual(appState.status, .idle)
                    idleExpectation.fulfill()
                }
            }
        }

        wait(for: [recordingExpectation, processingExpectation, idleExpectation], timeout: 2.0)
    }
}
