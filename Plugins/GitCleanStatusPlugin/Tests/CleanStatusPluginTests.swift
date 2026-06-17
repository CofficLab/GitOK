@testable import GitCleanStatusPlugin
import GitOKCoreKit
import SwiftUI
import Testing

@Suite("GitCleanStatusPlugin")
struct GitCleanStatusPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitCleanStatusPlugin.metadata.id == "GitCleanStatusPlugin")
        #expect(GitCleanStatusPlugin.metadata.iconName == "checkmark.circle")
        #expect(GitCleanStatusPlugin.metadata.order == 24)
        #expect(GitCleanStatusPlugin.metadata.tableName == "Localizable")
    }

    @Test("localized description resolves")
    func localizedDescription() {
        #expect(GitCleanStatusPlugin.metadata.description.isEmpty == false)
    }

    @Test("GitOKPluginContext clean status defaults")
    @MainActor
    func contextDefaults() {
        let context = GitOKPluginContext()
        #expect(context.projectURL == nil)
        context.onCleanStatusUpdate(true)
        context.onCleanStatusUpdate(false)
    }

    @Test("GitOKPluginContext with explicit projectURL")
    @MainActor
    func contextWithProjectURL() {
        let url = URL(fileURLWithPath: "/tmp/test-repo")
        var capturedValue: Bool?
        let context = GitOKPluginContext(
            projectURL: url,
            onCleanStatusUpdate: { isClean in
                capturedValue = isClean
            }
        )
        #expect(context.projectURL == url)
        context.onCleanStatusUpdate(true)
        #expect(capturedValue == true)
        context.onCleanStatusUpdate(false)
        #expect(capturedValue == false)
    }

    @Test("GitOKPluginContext with nil projectURL")
    @MainActor
    func contextWithNilURL() {
        var capturedValue: Bool?
        let context = GitOKPluginContext(
            projectURL: nil,
            onCleanStatusUpdate: { isClean in
                capturedValue = isClean
            }
        )
        #expect(context.projectURL == nil)
        context.onCleanStatusUpdate(true)
        #expect(capturedValue == true)
    }

    @Test("rootView returns a non-nil view")
    @MainActor
    func rootViewReturnsView() {
        let view = GitCleanStatusPlugin.rootOverlay(context: GitOKPluginContext(), content: AnyView(EmptyView()))
        #expect(view != nil)
    }

    @Test("localized strings resolve")
    func localizedStrings() {
        let s = GitCleanStatusPluginLocalization.string("Clean Status")
        #expect(s.isEmpty == false)
    }
}
