import Testing

@Suite("SSHHelperTests")
struct SSHHelperTests {
    @Test("Does not treat ssh scheme as username when URL already uses ssh scheme")
    func preservesExistingSSHURLSchemeWhenConvertingPort() {
        let convertedURL = SSHHelper.convertToSSHURL(
            "ssh://git@codebowl.juhe.cn:2014/juhe-web/west-home.git",
            hostname: "codebowl.juhe.cn",
            port: 2014
        )

        #expect(convertedURL == "ssh://git@codebowl.juhe.cn:2014/juhe-web/west-home.git")
        #expect(!convertedURL.hasPrefix("ssh://ssh://"))
    }

    @Test("Converts scp-like SSH remote to explicit ssh URL")
    func convertsScpLikeRemoteToSSHURL() {
        let convertedURL = SSHHelper.convertToSSHURL(
            "git@codebowl.juhe.cn:juhe-web/west-home.git",
            hostname: "codebowl.juhe.cn",
            port: 2014
        )

        #expect(convertedURL == "ssh://git@codebowl.juhe.cn:2014/juhe-web/west-home.git")
    }
}
