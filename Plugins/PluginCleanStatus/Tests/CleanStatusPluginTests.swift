@testable import PluginCleanStatus
import SwiftUI
import Testing

@Suite("PluginCleanStatus")
struct CleanStatusPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(CleanStatusPlugin.metadata.id == "CleanStatusPlugin")
        #expect(CleanStatusPlugin.metadata.iconName == "checkmark.circle")
        #expect(CleanStatusPlugin.metadata.order == 24)
        #expect(CleanStatusPlugin.metadata.allowUserToggle == false)
        #expect(CleanStatusPlugin.metadata.defaultEnabled == true)
        #expect(CleanStatusPlugin.metadata.tableName == "CleanStatus")
    }

    @Test("localized description resolves")
    func localizedDescription() {
        #expect(CleanStatusPlugin.metadata.description.isEmpty == false)
    }

    @Test("CleanStatusPluginContext default values")
    @MainActor
    func contextDefaults() {
        let context = CleanStatusPluginContext()
        #expect(context.projectURL == nil)
        context.updateCleanStatus(true)
        context.updateCleanStatus(false)
    }

    @Test("CleanStatusPluginContext with explicit projectURL")
    @MainActor
    func contextWithProjectURL() {
        let url = URL(fileURLWithPath: "/tmp/test-repo")
        var capturedValue: Bool?
        let context = CleanStatusPluginContext(
            projectURL: url,
            updateCleanStatus: { isClean in
                capturedValue = isClean
            }
        )
        #expect(context.projectURL == url)
        context.updateCleanStatus(true)
        #expect(capturedValue == true)
        context.updateCleanStatus(false)
        #expect(capturedValue == false)
    }

    @Test("CleanStatusPluginContext with nil projectURL")
    @MainActor
    func contextWithNilURL() {
        var capturedValue: Bool?
        let context = CleanStatusPluginContext(
            projectURL: nil,
            updateCleanStatus: { isClean in
                capturedValue = isClean
            }
        )
        #expect(context.projectURL == nil)
        context.updateCleanStatus(true)
        #expect(capturedValue == true)
    }

    @Test("rootView returns a non-nil view")
    @MainActor
    func rootViewReturnsView() {
        let view = CleanStatusPlugin.shared.rootView(AnyView(EmptyView()))
        #expect(view != nil)
    }

    @Test("localized strings resolve")
    func localizedStrings() {
        let s = PluginCleanStatusLocalization.string("Clean Status")
        #expect(s.isEmpty == false)
    }
}
