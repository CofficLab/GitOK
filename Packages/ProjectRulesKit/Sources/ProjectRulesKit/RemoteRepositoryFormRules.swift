import Foundation

public enum RemoteRepositoryFormRules {
    public enum HostingProvider: String, CaseIterable, Sendable {
        case github = "GitHub"
        case gitlab = "GitLab"
        case bitbucket = "Bitbucket"
        case azureDevOps = "Azure DevOps"
        case unknown = "Unknown"

        public var authenticationNote: String {
            switch self {
            case .github:
                return "GitHub HTTPS 通常使用 token 或 credential helper，SSH 使用本机 keychain/agent 中的密钥。"
            case .gitlab:
                return "GitLab HTTPS 可使用 personal/project access token，SSH 使用已配置的 SSH key。"
            case .bitbucket:
                return "Bitbucket HTTPS 通常使用 app password 或 workspace token，SSH 使用已配置的 SSH key。"
            case .azureDevOps:
                return "Azure DevOps HTTPS 常见为 PAT 或企业身份登录，SSH URL 受组织策略和 key 配置影响。"
            case .unknown:
                return "未识别的 Git 托管平台会按通用 Git 远程处理，认证方式取决于服务器配置。"
            }
        }
    }

    public struct RemoteWebLink: Equatable, Sendable {
        public let provider: HostingProvider
        public let url: URL

        public init(provider: HostingProvider, url: URL) {
            self.provider = provider
            self.url = url
        }

        public var authenticationNote: String {
            provider.authenticationNote
        }
    }

    public struct PullRequestWebLinks: Equatable, Sendable {
        public let provider: HostingProvider
        public let listURL: URL
        public let createURL: URL
        public let branchURL: URL
        public let reviewRequestsURL: URL
        public let commentsURL: URL
        public let notificationsURL: URL

        public init(
            provider: HostingProvider,
            listURL: URL,
            createURL: URL,
            branchURL: URL,
            reviewRequestsURL: URL,
            commentsURL: URL,
            notificationsURL: URL
        ) {
            self.provider = provider
            self.listURL = listURL
            self.createURL = createURL
            self.branchURL = branchURL
            self.reviewRequestsURL = reviewRequestsURL
            self.commentsURL = commentsURL
            self.notificationsURL = notificationsURL
        }
    }

    public static func normalizedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func normalizedInput(name: String, url: String) -> (name: String, url: String) {
        (
            name: normalizedValue(name),
            url: normalizedValue(url)
        )
    }

    public static func isFormValid(name: String, url: String) -> Bool {
        let input = normalizedInput(name: name, url: url)
        return !input.name.isEmpty && !input.url.isEmpty
    }

    public static func hasChanges(
        originalName: String,
        originalURL: String,
        editedName: String,
        editedURL: String
    ) -> Bool {
        let input = normalizedInput(name: editedName, url: editedURL)
        return input.name != originalName || input.url != originalURL
    }

    public static func deleteWarning(remoteName: String, isCurrentUpstreamRemote: Bool) -> String {
        if isCurrentUpstreamRemote {
            return "删除远程仓库 \"\(remoteName)\" 会移除当前分支的远程跟踪关系，Push/Pull 状态会变为无 upstream。此操作不可撤销。"
        }
        return "确定要删除远程仓库 \"\(remoteName)\" 吗？依赖它的远程分支、标签推送和后续 Fetch/Pull 操作都会受影响。此操作不可撤销。"
    }

    public static func remoteWebLink(for remoteURL: String) -> RemoteWebLink? {
        let normalizedURL = normalizedValue(remoteURL)
        guard normalizedURL.isEmpty == false else { return nil }

        if let scpLikeURL = webURLFromSCPLikeRemote(normalizedURL) {
            return RemoteWebLink(provider: hostingProvider(for: scpLikeURL), url: scpLikeURL)
        }

        guard var components = URLComponents(string: normalizedURL) else { return nil }

        switch components.scheme?.lowercased() {
        case "http", "https":
            break
        case "ssh":
            components.scheme = "https"
            components.user = nil
            components.password = nil
        case "git":
            components.scheme = "https"
        default:
            return nil
        }

        components.query = nil
        components.fragment = nil
        components.path = pathWithoutGitSuffix(components.path)

        guard let url = components.url, url.host?.isEmpty == false else { return nil }
        return RemoteWebLink(provider: hostingProvider(for: url), url: url)
    }

    public static func hostingProvider(for remoteURL: String) -> HostingProvider {
        guard let link = remoteWebLink(for: remoteURL) else { return .unknown }
        return link.provider
    }

    public static func pullRequestWebLinks(remoteURL: String, baseBranch: String, headBranch: String) -> PullRequestWebLinks? {
        guard let link = remoteWebLink(for: remoteURL) else { return nil }

        let base = normalizedValue(baseBranch)
        let head = normalizedValue(headBranch)
        guard base.isEmpty == false, head.isEmpty == false else { return nil }

        let encodedBase = pathEncodedBranch(base)
        let encodedHead = pathEncodedBranch(head)

        switch link.provider {
        case .github:
            return PullRequestWebLinks(
                provider: link.provider,
                listURL: link.url.appendingPathComponent("pulls"),
                createURL: link.url.appendingPathComponent("compare/\(encodedBase)...\(encodedHead)"),
                branchURL: link.url.appendingPathComponent("pulls").appending(queryItems: [
                    URLQueryItem(name: "q", value: "is:pr head:\(head)")
                ]),
                reviewRequestsURL: link.url.appendingPathComponent("pulls").appending(queryItems: [
                    URLQueryItem(name: "q", value: "is:pr review-requested:@me")
                ]),
                commentsURL: link.url.appendingPathComponent("pulls").appending(queryItems: [
                    URLQueryItem(name: "q", value: "is:pr commenter:@me")
                ]),
                notificationsURL: URL(string: "https://github.com/notifications?query=reason%3Areview-requested") ?? link.url.appendingPathComponent("pulls")
            )
        case .gitlab:
            let mergeRequestsURL = link.url.appendingPathComponent("-/merge_requests")
            return PullRequestWebLinks(
                provider: link.provider,
                listURL: mergeRequestsURL,
                createURL: link.url.appendingPathComponent("-/merge_requests/new").appending(queryItems: [
                    URLQueryItem(name: "merge_request[source_branch]", value: head),
                    URLQueryItem(name: "merge_request[target_branch]", value: base),
                ]),
                branchURL: mergeRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "scope", value: "all"),
                    URLQueryItem(name: "state", value: "opened"),
                    URLQueryItem(name: "source_branch", value: head),
                ]),
                reviewRequestsURL: mergeRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "reviewer_username", value: "@me"),
                    URLQueryItem(name: "state", value: "opened"),
                ]),
                commentsURL: mergeRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "scope", value: "all"),
                    URLQueryItem(name: "state", value: "opened"),
                ]),
                notificationsURL: link.url.appendingPathComponent("-/activity")
            )
        case .bitbucket:
            let pullRequestsURL = link.url.appendingPathComponent("pull-requests")
            return PullRequestWebLinks(
                provider: link.provider,
                listURL: pullRequestsURL,
                createURL: link.url.appendingPathComponent("pull-requests/new").appending(queryItems: [
                    URLQueryItem(name: "source", value: head),
                    URLQueryItem(name: "dest", value: base),
                ]),
                branchURL: pullRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "source", value: head),
                ]),
                reviewRequestsURL: pullRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "state", value: "OPEN"),
                ]),
                commentsURL: pullRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "state", value: "OPEN"),
                ]),
                notificationsURL: link.url.appendingPathComponent("pull-requests")
            )
        case .azureDevOps:
            let pullRequestsURL = link.url.appendingPathComponent("pullrequests")
            return PullRequestWebLinks(
                provider: link.provider,
                listURL: pullRequestsURL,
                createURL: link.url.appendingPathComponent("pullrequestcreate").appending(queryItems: [
                    URLQueryItem(name: "sourceRef", value: "refs/heads/\(head)"),
                    URLQueryItem(name: "targetRef", value: "refs/heads/\(base)"),
                ]),
                branchURL: pullRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "searchCriteria.sourceRefName", value: "refs/heads/\(head)"),
                ]),
                reviewRequestsURL: pullRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "reviewer", value: "@me"),
                    URLQueryItem(name: "status", value: "active"),
                ]),
                commentsURL: pullRequestsURL.appending(queryItems: [
                    URLQueryItem(name: "status", value: "active"),
                ]),
                notificationsURL: link.url.appendingPathComponent("pullrequests").appending(queryItems: [
                    URLQueryItem(name: "status", value: "active"),
                ])
            )
        case .unknown:
            return nil
        }
    }

    private static func webURLFromSCPLikeRemote(_ remoteURL: String) -> URL? {
        guard remoteURL.contains("://") == false,
              let separator = remoteURL.firstIndex(of: ":")
        else { return nil }

        let accountAndHost = String(remoteURL[..<separator])
        let pathStart = remoteURL.index(after: separator)
        let rawPath = String(remoteURL[pathStart...])
        let host = accountAndHost.split(separator: "@").last.map(String.init) ?? accountAndHost

        guard host.isEmpty == false, rawPath.isEmpty == false else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/" + pathWithoutGitSuffix(rawPath)
        return components.url
    }

    private static func hostingProvider(for webURL: URL) -> HostingProvider {
        guard let host = webURL.host?.lowercased() else { return .unknown }

        if host == "ssh.dev.azure.com" || host == "dev.azure.com" || host.hasSuffix(".visualstudio.com") {
            return .azureDevOps
        }
        if host == "github.com" || host.contains("github.") {
            return .github
        }
        if host == "gitlab.com" || host.contains("gitlab.") {
            return .gitlab
        }
        if host == "bitbucket.org" || host.contains("bitbucket.") {
            return .bitbucket
        }
        return .unknown
    }

    private static func pathWithoutGitSuffix(_ path: String) -> String {
        guard path.hasSuffix(".git") else { return path }
        return String(path.dropLast(4))
    }

    private static func pathEncodedBranch(_ branch: String) -> String {
        branch
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { part in
                String(part).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(part)
            }
            .joined(separator: "/")
    }

    private static func queryEncodedBranch(_ branch: String) -> String {
        branch.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? branch
    }

    private static func azureProjectURL(from repositoryURL: URL) -> URL? {
        let components = repositoryURL.pathComponents
        guard let gitIndex = components.firstIndex(of: "_git"), gitIndex >= 2 else {
            return nil
        }

        var urlComponents = URLComponents(url: repositoryURL, resolvingAgainstBaseURL: false)
        urlComponents?.query = nil
        urlComponents?.fragment = nil
        urlComponents?.path = "/" + components[1..<gitIndex].joined(separator: "/")
        return urlComponents?.url
    }
}
