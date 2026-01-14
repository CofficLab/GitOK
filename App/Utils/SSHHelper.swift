import Foundation

// MARK: - SSH Helper

/// SSH 辅助工具
/// 用于解析 ~/.ssh/config 并处理 SSH URL 转换
struct SSHHelper {

    /// 从 ~/.ssh/config 中查找主机配置并返回转换后的 URL
    /// - Parameter originalURL: 原始 Git URL（例如 git@host:path）
    /// - Returns: 转换后的 URL（如果需要转换）
    static func applySSHConfig(to originalURL: String) -> String {
        print("🔍 [SSHHelper] Processing URL: \(originalURL)")

        // 只处理 SSH URL
        guard originalURL.contains("@") && !originalURL.hasPrefix("https://") else {
            print("ℹ️ [SSHHelper] Not an SSH URL, returning original")
            return originalURL
        }

        // 提取主机名
        let hostname = extractHostname(from: originalURL)
        print("🔍 [SSHHelper] Extracted hostname: \(hostname)")

        guard !hostname.isEmpty else {
            print("⚠️ [SSHHelper] Failed to extract hostname")
            return originalURL
        }

        // 查找 SSH 配置
        guard let config = parseSSHConfig(for: hostname) else {
            print("ℹ️ [SSHHelper] No SSH config found for \(hostname)")
            return originalURL
        }

        print("✅ [SSHHelper] Found SSH config - host: \(config.host), hostname: \(config.hostName ?? "nil"), port: \(config.port?.description ?? "nil")")

        // 如果端口不是 22，需要转换 URL
        guard let port = config.port, port != 22 else {
            print("ℹ️ [SSHHelper] Port is 22 or not set, no conversion needed")
            return originalURL
        }

        // 转换为 ssh:// 格式
        let convertedURL = convertToSSHURL(originalURL, hostname: config.hostName ?? hostname, port: port)
        print("🔄 [SSHHelper] Converting to: \(convertedURL)")
        return convertedURL
    }

    /// 从 SSH URL 中提取主机名
    private static func extractHostname(from url: String) -> String {
        // 处理 ssh:// 格式
        if url.hasPrefix("ssh://") {
            let pattern = "^ssh://[^@]+@([^:/]+)"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        } else {
            // 处理 git@host:path 格式
            let pattern = "^[^@]+@([^:]+):"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        return ""
    }

    /// 解析 ~/.ssh/config 文件
    private static func parseSSHConfig(for hostname: String) -> (host: String, hostName: String?, port: Int?)? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let configPath = "\(homeDir)/.ssh/config"

        guard FileManager.default.fileExists(atPath: configPath) else {
            print("⚠️ [SSHHelper] Config file not found: \(configPath)")
            return nil
        }

        do {
            let content = try String(contentsOfFile: configPath, encoding: .utf8)
            var configs: [(host: String, hostName: String?, port: Int?)] = []
            var currentHost: String?
            var currentHostName: String?
            var currentPort: Int?

            let lines = content.components(separatedBy: .newlines)

            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)

                // 跳过空行和注释
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }

                // 检查是否是 Host 行
                // 必须是完整的 "Host" 单词，而不是 "Hostname" 等其他词
                let isHostLine: Bool
                if trimmedLine.lowercased().hasPrefix("host") {
                    let afterHost = trimmedLine.dropFirst(4)
                    // 检查第5个字符是否是空白字符
                    isHostLine = afterHost.isEmpty || afterHost.first?.isWhitespace == true
                } else {
                    isHostLine = false
                }

                if isHostLine {
                    // 保存之前的配置
                    if let host = currentHost {
                        print("📝 [SSHHelper] Saving config for: \(host) -> hostname: \(currentHostName ?? "nil"), port: \(currentPort?.description ?? "nil")")
                        configs.append((host, currentHostName, currentPort))
                    }

                    // 开始新的配置
                    let hostValue = trimmedLine.dropFirst(4).trimmingCharacters(in: .whitespaces)
                    print("🔖 [SSHHelper] Found Host: \(hostValue)")
                    currentHost = hostValue
                    currentHostName = nil
                    currentPort = nil
                } else if currentHost != nil {
                    // 解析配置项
                    // 使用正则表达式处理空格和 Tab 混合的情况
                    let pattern = "^(\\w+)\\s+(.+)$"
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       let match = regex.firstMatch(in: trimmedLine, range: NSRange(trimmedLine.startIndex..., in: trimmedLine)) {

                        if match.numberOfRanges >= 3,
                           let keyRange = Range(match.range(at: 1), in: trimmedLine),
                           let valueRange = Range(match.range(at: 2), in: trimmedLine) {

                            let key = String(trimmedLine[keyRange]).lowercased()
                            let value = String(trimmedLine[valueRange])

                            print("  🔧 [SSHHelper] Key: \(key), Value: \(value)")

                            switch key {
                            case "hostname":
                                currentHostName = value
                            case "port":
                                currentPort = Int(value)
                            default:
                                break
                            }
                        }
                    } else {
                        print("  ⚠️ [SSHHelper] Failed to parse line: \(trimmedLine)")
                    }
                }
            }

            // 保存最后一个配置
            if let host = currentHost {
                print("📝 [SSHHelper] Saving final config for: \(host) -> hostname: \(currentHostName ?? "nil"), port: \(currentPort?.description ?? "nil")")
                configs.append((host, currentHostName, currentPort))
            }

            print("📊 [SSHHelper] Total configs parsed: \(configs.count)")

            // 查找匹配的配置
            for config in configs {
                if config.host == hostname || config.host == "*" {
                    print("✅ [SSHHelper] Matched config: \(config.host)")
                    return config
                }
            }

        } catch {
            print("Failed to read SSH config: \(error)")
        }

        return nil
    }

    /// 转换为 ssh:// 格式
    private static func convertToSSHURL(_ originalURL: String, hostname: String, port: Int) -> String {
        // 从原始 URL 提取用户和路径
        let pattern = "^([^@]+)@[^:]+:(.+)$"

        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: originalURL, range: NSRange(originalURL.startIndex..., in: originalURL)) {

            let user = String(originalURL[Range(match.range(at: 1), in: originalURL)!])
            let path = String(originalURL[Range(match.range(at: 2), in: originalURL)!])

            return "ssh://\(user)@\(hostname):\(port)/\(path)"
        }

        return originalURL
    }
}
