import XCTest
@testable import KernelCore

@MainActor
final class KernelCoreTests: XCTestCase {
    func testRegistersAndResolvesTypedProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(String.self, "GitOK")

        XCTAssertEqual(kernel.resolveProvider(String.self), "GitOK")
        XCTAssertEqual(kernel.registeredProviderCount, 1)
    }

    func testRejectsDuplicateProviderType() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(String.self, "first")

        XCTAssertThrowsError(try kernel.registerProvider(String.self, "second")) { error in
            XCTAssertEqual(
                error as? KernelCoreError,
                .providerAlreadyRegistered(type: "Swift.String")
            )
        }
    }

    func testLifecycleIsExplicit() throws {
        let kernel = KernelCoreContainer()
        XCTAssertEqual(kernel.lifecycleState, .stopped)

        try kernel.start()
        XCTAssertEqual(kernel.lifecycleState, .running)

        try kernel.stop()
        XCTAssertEqual(kernel.lifecycleState, .stopped)
    }

    func testUnregisterRemovesProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider(String.self, "GitOK")

        kernel.unregisterProvider(String.self)

        XCTAssertNil(kernel.resolveProvider(String.self))
        XCTAssertEqual(kernel.registeredProviderCount, 0)
    }

    func testPluginLifecycleUsesDependencyAndOrder() throws {
        let kernel = KernelCoreContainer()
        let recorder = PluginRecorder()

        try kernel.start(plugins: [
            RecordingPlugin(id: "feature", order: 20, recorder: recorder, dependencies: ["base"]),
            RecordingPlugin(id: "base", order: 10, recorder: recorder),
        ])

        XCTAssertEqual(recorder.events, ["base.boot", "feature.boot", "base.ready", "feature.ready"])
        XCTAssertEqual(kernel.registeredPluginCount, 2)

        try kernel.stop()
        XCTAssertEqual(Array(recorder.events.suffix(2)), ["feature.shutdown", "base.shutdown"])
    }
}

@MainActor
private final class PluginRecorder {
    var events: [String] = []
}

@MainActor
private struct RecordingPlugin: KernelPlugin {
    let id: String
    let order: Int
    let recorder: PluginRecorder
    var dependencies: [String] = []

    func onBoot(kernel: KernelCoreContainer) throws { recorder.events.append("\(id).boot") }
    func onReady(kernel: KernelCoreContainer) throws { recorder.events.append("\(id).ready") }
    func onShutdown(kernel: KernelCoreContainer) throws { recorder.events.append("\(id).shutdown") }
}
