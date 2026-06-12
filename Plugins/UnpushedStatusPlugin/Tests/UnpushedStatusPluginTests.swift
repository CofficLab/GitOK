import GitOKCoreKit
@testable import UnpushedStatusPlugin
import Testing

@Suite("UnpushedStatusPlugin")
struct UnpushedStatusPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(UnpushedStatusPlugin.metadata.id == "UnpushedStatusPlugin")
        #expect(UnpushedStatusPlugin.metadata.iconName == "arrow.up.circle")
        #expect(UnpushedStatusPlugin.metadata.order == 25)
        #expect(UnpushedStatusPlugin.metadata.tableName == "Localizable")
    }

    @Test("remote tracking status maps from GitCoreKit")
    func remoteTrackingStatusMapsFromGitCoreKit() {
        let status = UnpushedStatusPresentation.remoteTrackingStatus(
            from: GitAheadBehind(ahead: 2, behind: 1, hasUpstream: true)
        )

        #expect(status.ahead == 2)
        #expect(status.behind == 1)
        #expect(status.hasUpstream)
    }
}
