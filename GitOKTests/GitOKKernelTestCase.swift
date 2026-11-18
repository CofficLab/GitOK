import KernelCore
import LumiFactory
import XCTest
@testable import GitOK

/// 内核装配测试基类：数据根经 `GITOK_UI_TEST_DATA_ROOT` 隔离到临时目录
/// （DEBUG 生效），不触碰用户真实数据。
@MainActor
class GitOKKernelTestCase: XCTestCase {
    private var dataRoot: URL!

    override func setUp() async throws {
        dataRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dataRoot, withIntermediateDirectories: true)
        setenv("GITOK_UI_TEST_DATA_ROOT", dataRoot.path, 1)
    }

    override func tearDown() async throws {
        unsetenv("GITOK_UI_TEST_DATA_ROOT")
        try? FileManager.default.removeItem(at: dataRoot)
        dataRoot = nil
    }

    /// 共享装配引擎解释 GitOK 清单后的真实内核。
    func makeKernel() async throws -> KernelCoreContainer {
        try await KernelAssembler.makeKernel(manifest: GitOKHostManifest.make())
    }
}