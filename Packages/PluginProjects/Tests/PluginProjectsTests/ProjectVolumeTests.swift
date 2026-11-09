import Foundation
import XCTest
@testable import PluginProjects

/// 卷类型判定的单元测试。
final class ProjectVolumeTests: XCTestCase {
    // MARK: - Classifier

    func testInternalVolumeWhenAllSignalsSayInternal() {
        let attributes = ProjectVolumeAttributes(
            isInternal: true,
            isEjectable: false,
            isRemovable: false,
            isLocal: true
        )

        XCTAssertEqual(ProjectVolumeClassifier.classify(attributes), .internalVolume)
    }

    func testExternalVolumeWhenNotInternal() {
        let attributes = ProjectVolumeAttributes(
            isInternal: false,
            isEjectable: false,
            isRemovable: false,
            isLocal: true
        )

        XCTAssertEqual(ProjectVolumeClassifier.classify(attributes), .externalVolume)
    }

    func testExternalVolumeWhenEjectable() {
        let attributes = ProjectVolumeAttributes(isEjectable: true)

        XCTAssertEqual(ProjectVolumeClassifier.classify(attributes), .externalVolume)
    }

    func testExternalVolumeWhenRemovable() {
        let attributes = ProjectVolumeAttributes(isRemovable: true)

        XCTAssertEqual(ProjectVolumeClassifier.classify(attributes), .externalVolume)
    }

    func testExternalVolumeWhenNetworkVolume() {
        // 网络卷不是本地卷，同样视为外接设备。
        let attributes = ProjectVolumeAttributes(isLocal: false)

        XCTAssertEqual(ProjectVolumeClassifier.classify(attributes), .externalVolume)
    }

    func testDefaultsToInternalWhenSignalsAreUnknown() {
        let attributes = ProjectVolumeAttributes()

        XCTAssertEqual(ProjectVolumeClassifier.classify(attributes), .internalVolume,
                       "卷属性读取成功但没有外接信号时，按本机卷处理")
    }

    // MARK: - Resolver

    func testResolverReportsUnavailableForMissingPath() async {
        let url = URL(fileURLWithPath: "/definitely/missing/gitok-volume-\(UUID().uuidString)")

        let status = await FileSystemProjectVolumeResolver().status(forProjectURL: url)

        XCTAssertEqual(status, .unavailable, "无法读取卷属性时应标记为不可访问")
    }

    func testResolverReadsAttributesForExistingPath() async {
        let url = FileManager.default.temporaryDirectory

        let status = await FileSystemProjectVolumeResolver().status(forProjectURL: url)

        XCTAssertNotEqual(status, .unavailable, "已存在的目录应能读取到卷属性")
    }
}
