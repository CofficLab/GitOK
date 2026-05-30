import Testing
@testable import GitCoreKit

@Suite("SSHConfigURLResolver")
struct SSHConfigURLResolverTests {
    @Test("converts scp-like urls when ssh config defines a custom port")
    func convertsScpLikeURLWithCustomPort() {
        let config = """
        Host github-work
          HostName github.com
          Port 443
        """

        let resolved = SSHConfigURLResolver.applySSHConfig(
            to: "git@github-work:owner/repo.git",
            configContent: config
        )

        #expect(resolved == "ssh://git@github.com:443/owner/repo.git")
    }

    @Test("keeps urls unchanged without a matching custom port")
    func keepsURLWhenNoPortIsConfigured() {
        let config = """
        Host github-work
          HostName github.com
        """

        let resolved = SSHConfigURLResolver.applySSHConfig(
            to: "git@github-work:owner/repo.git",
            configContent: config
        )

        #expect(resolved == "git@github-work:owner/repo.git")
    }
}
