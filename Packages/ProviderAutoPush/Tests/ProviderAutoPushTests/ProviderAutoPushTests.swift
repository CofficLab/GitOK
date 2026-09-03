import Foundation
import KernelCore
import ProviderStorage
import Testing
@testable import ProviderAutoPush

@Suite("ProviderAutoPush")
@MainActor
struct ProviderAutoPushTests {

    @Test("开关按项目路径持久化")
    func enabledPerProject() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AutoPushTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let storage = TestStorage(pluginDir: directory)
        let provider = DefaultAutoPushProvider(storage: storage)

        let a = URL(fileURLWithPath: "/tmp/repo-a")
        let b = URL(fileURLWithPath: "/tmp/repo-b")
        #expect(provider.isEnabled(for: a) == false)

        provider.setEnabled(true, for: a)
        #expect(provider.isEnabled(for: a) == true)
        #expect(provider.isEnabled(for: b) == false)

        // 新实例应能读到已保存的开关。
        let reloaded = DefaultAutoPushProvider(storage: storage)
        #expect(reloaded.isEnabled(for: a) == true)
    }
}

@MainActor
private final class TestStorage: StorageProviding {
    let pluginDir: URL
    init(pluginDir: URL) {
        self.pluginDir = pluginDir
    }

    var dataRootDirectory: URL {
        pluginDir
    }

    func pluginDataDirectory(for pluginID: String) -> URL {
        pluginDir.appendingPathComponent(pluginID)
    }

    func coreDataDirectory() -> URL {
        pluginDir
    }
}
