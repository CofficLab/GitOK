import Foundation

public enum SSHConfigURLResolver {
    public struct HostConfig: Equatable, Sendable {
        public let host: String
        public let hostName: String?
        public let port: Int?

        public init(host: String, hostName: String?, port: Int?) {
            self.host = host
            self.hostName = hostName
            self.port = port
        }
    }

    public static func applySSHConfig(
        to originalURL: String,
        configContent: String? = nil,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> String {
        guard originalURL.contains("@"), !originalURL.hasPrefix("https://") else {
            return originalURL
        }

        let hostname = extractHostname(from: originalURL)
        guard !hostname.isEmpty else { return originalURL }

        let content: String
        if let configContent {
            content = configContent
        } else {
            let configURL = homeDirectory.appendingPathComponent(".ssh/config")
            guard let loaded = try? String(contentsOf: configURL, encoding: .utf8) else {
                return originalURL
            }
            content = loaded
        }

        guard let config = parseSSHConfig(content, hostname: hostname),
              let port = config.port,
              port != 22 else {
            return originalURL
        }

        return convertToSSHURL(originalURL, hostname: config.hostName ?? hostname, port: port)
    }

    public static func extractHostname(from url: String) -> String {
        if url.hasPrefix("ssh://") {
            let pattern = #"^ssh://[^@]+@([^:/]+)"#
            return firstCapture(in: url, pattern: pattern) ?? ""
        }

        let pattern = #"^[^@]+@([^:]+):"#
        return firstCapture(in: url, pattern: pattern) ?? ""
    }

    public static func parseSSHConfig(_ content: String, hostname: String) -> HostConfig? {
        var configs: [HostConfig] = []
        var currentHost: String?
        var currentHostName: String?
        var currentPort: Int?

        func flushCurrent() {
            guard let currentHost else { return }
            configs.append(HostConfig(host: currentHost, hostName: currentHostName, port: currentPort))
        }

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let lower = trimmed.lowercased()
            let isHostLine = lower.hasPrefix("host") && (trimmed.dropFirst(4).first?.isWhitespace ?? true)
            if isHostLine {
                flushCurrent()
                currentHost = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
                currentHostName = nil
                currentPort = nil
                continue
            }

            guard currentHost != nil else { continue }
            let components = trimmed.split(maxSplits: 1, whereSeparator: { $0.isWhitespace })
            guard components.count == 2 else { continue }

            switch components[0].lowercased() {
            case "hostname":
                currentHostName = String(components[1])
            case "port":
                currentPort = Int(components[1])
            default:
                break
            }
        }

        flushCurrent()
        return configs.first { $0.host == hostname || $0.host == "*" }
    }

    public static func convertToSSHURL(_ originalURL: String, hostname: String, port: Int) -> String {
        if originalURL.hasPrefix("ssh://"),
           var components = URLComponents(string: originalURL),
           components.scheme == "ssh",
           components.user != nil,
           !components.path.isEmpty {
            components.host = hostname
            components.port = port
            return components.string ?? originalURL
        }

        let pattern = #"^([^@/:]+)@[^:]+:(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: originalURL, range: NSRange(originalURL.startIndex..., in: originalURL)),
              let userRange = Range(match.range(at: 1), in: originalURL),
              let pathRange = Range(match.range(at: 2), in: originalURL) else {
            return originalURL
        }

        return "ssh://\(originalURL[userRange])@\(hostname):\(port)/\(originalURL[pathRange])"
    }

    private static func firstCapture(in value: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              let range = Range(match.range(at: 1), in: value) else {
            return nil
        }
        return String(value[range])
    }
}
