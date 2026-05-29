@testable import PluginGitPush
import Testing

@Suite("PluginGitPush")
struct GitPushPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitPushPlugin.metadata.id == "GitPushPlugin")
        #expect(GitPushPlugin.metadata.iconName == "arrow.triangle.2.circlepath")
        #expect(GitPushPlugin.metadata.allowUserToggle == true)
        #expect(GitPushPlugin.metadata.defaultEnabled == true)
        #expect(GitPushPlugin.metadata.tableName == "GitPush")
    }

    @Test("localized display name resolves")
    func localizedDisplayName() {
        #expect(GitPushPlugin.metadata.displayName.isEmpty == false)
    }
}
