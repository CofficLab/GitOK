import Foundation
import XCTest
@testable import PluginProjects

/// 项目展示方式偏好的持久化测试。
@MainActor
final class ProjectSortModeStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUpWithError() throws {
        suiteName = "PluginProjectsSortModeTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
    }

    func testLoadReturnsNilWhenNothingStored() {
        let store = UserDefaultsProjectSortModeStore(defaults: defaults, key: "sort-mode")

        XCTAssertNil(store.loadSortMode())
    }

    func testSaveThenLoadRoundTrips() {
        let store = UserDefaultsProjectSortModeStore(defaults: defaults, key: "sort-mode")

        store.saveSortMode(.name)

        XCTAssertEqual(store.loadSortMode(), .name)
    }

    func testLoadIgnoresUnknownStoredValue() {
        defaults.set("not-a-mode", forKey: "sort-mode")
        let store = UserDefaultsProjectSortModeStore(defaults: defaults, key: "sort-mode")

        XCTAssertNil(store.loadSortMode(), "无法识别的存档应回落到默认展示方式")
    }

    func testSavePersistsUnderConfiguredKey() {
        let store = UserDefaultsProjectSortModeStore(defaults: defaults, key: "custom-key")

        store.saveSortMode(.recent)

        XCTAssertEqual(defaults.string(forKey: "custom-key"), ProjectSortMode.recent.rawValue)
    }
}
