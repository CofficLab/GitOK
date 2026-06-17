import GitOKCoreKit
@testable import GitUnpushedStatusPlugin
import Testing

@Suite("GitUnpushedStatusPlugin")
struct GitUnpushedStatusPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(GitUnpushedStatusPlugin.metadata.id == "GitUnpushedStatusPlugin")
        #expect(GitUnpushedStatusPlugin.metadata.iconName == "arrow.up.circle")
        #expect(GitUnpushedStatusPlugin.metadata.order == 25)
        #expect(GitUnpushedStatusPlugin.metadata.tableName == "Localizable")
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
