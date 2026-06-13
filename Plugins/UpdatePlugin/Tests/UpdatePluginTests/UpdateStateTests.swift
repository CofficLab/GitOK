import XCTest
@testable import UpdatePlugin

final class UpdateStateTests: XCTestCase {

    // MARK: - State Equality Tests

    func testIdleStateEquality() {
        let state1 = UpdateState.idle
        let state2 = UpdateState.idle

        XCTAssertEqual(state1, state2)
    }

    func testCheckingStateEquality() {
        let state1 = UpdateState.checking
        let state2 = UpdateState.checking

        XCTAssertEqual(state1, state2)
    }

    func testAvailableStateEquality() {
        let updateInfo = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["url"],
            releaseNotes: "Test"
        )

        let state1 = UpdateState.available(updateInfo: updateInfo)
        let state2 = UpdateState.available(updateInfo: updateInfo)

        XCTAssertEqual(state1, state2)
    }

    func testAvailableStateInequality() {
        let info1 = UpdateInfo(
            version: "3.0.11",
            buildNumber: 123456,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["url"],
            releaseNotes: "Test"
        )

        let info2 = UpdateInfo(
            version: "3.0.12",
            buildNumber: 123457,
            releaseDate: "2026-06-13T00:00:00Z",
            downloadUrls: ["url"],
            releaseNotes: "Test"
        )

        let state1 = UpdateState.available(updateInfo: info1)
        let state2 = UpdateState.available(updateInfo: info2)

        XCTAssertNotEqual(state1, state2)
    }

    func testDownloadingStateEquality() {
        let state1 = UpdateState.downloading(progress: 0.5, speed: "5.0 MB/s")
        let state2 = UpdateState.downloading(progress: 0.5, speed: "5.0 MB/s")

        XCTAssertEqual(state1, state2)
    }

    func testDownloadingStateInequality() {
        let state1 = UpdateState.downloading(progress: 0.5, speed: "5.0 MB/s")
        let state2 = UpdateState.downloading(progress: 0.6, speed: "5.0 MB/s")

        XCTAssertNotEqual(state1, state2)
    }

    func testInstallingStateEquality() {
        let state1 = UpdateState.installing(progress: "Installing...")
        let state2 = UpdateState.installing(progress: "Installing...")

        XCTAssertEqual(state1, state2)
    }

    func testCompletedStateEquality() {
        let state1 = UpdateState.completed
        let state2 = UpdateState.completed

        XCTAssertEqual(state1, state2)
    }

    func testErrorStateEquality() {
        let state1 = UpdateState.error(message: "Test error")
        let state2 = UpdateState.error(message: "Test error")

        XCTAssertEqual(state1, state2)
    }

    func testDifferentStatesInequality() {
        let state1 = UpdateState.idle
        let state2 = UpdateState.checking

        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Sendable Conformance Tests

    func testStateSendable() {
        // UpdateState should conform to Sendable
        let state = UpdateState.checking

        // This test ensures Sendable conformance at compile time
        let _: @Sendable () -> Void = {
            _ = state
        }
    }
}