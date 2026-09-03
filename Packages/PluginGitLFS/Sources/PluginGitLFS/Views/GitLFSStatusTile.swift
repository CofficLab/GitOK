import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// Git LFS 状态图标：检测 git-lfs 可用性，扫描 >50MB 大文件并推荐纳入 LFS
/// （对齐旧版 GitLFSStatusTile 的核心能力）。
public struct GitLFSStatusTile: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var isPresented = false
    @State private var isLoading = true
    @State private var isLFSAvailable = false
    @State private var lfsVersion: String?
    @State private var largeFiles: [String] = []

    private let thresholdBytes: Int64 = 50 * 1024 * 1024

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                Image(systemName: largeFiles.isEmpty ? "externaldrive" : "externaldrive.badge.exclamationmark")
                    .font(.system(size: 10))
                    .foregroundStyle(largeFiles.isEmpty ? theme.textSecondary : theme.warning)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPresented = true
                    }
                    .help(largeFiles.isEmpty
                        ? "LFS status normal"
                        : "Found \(largeFiles.count) large file(s) to track with Git LFS")
                    .popover(isPresented: $isPresented) {
                        GitLFSContentView(
                            isLFSAvailable: isLFSAvailable,
                            lfsVersion: lfsVersion,
                            largeFiles: largeFiles,
                            onInitialize: initializeLFS
                        )
                        .frame(width: 420)
                        .padding(16)
                    }
            }
        }
        .onReceive(observation.$revision) { _ in refresh() }
        .onAppear(perform: refresh)
    }

    @MainActor
    private func refresh() {
        guard let projectURL = projects.currentProject?.url else {
            largeFiles = []
            isLFSAvailable = false
            isLoading = false
            return
        }
        isLoading = true
        Task.detached(priority: .utility) {
            let lfsAvailable = Self.gitBinaryAvailable("git-lfs")
            let files = Self.scanLargeFiles(in: projectURL, thresholdBytes: thresholdBytes)
            await MainActor.run {
                isLFSAvailable = lfsAvailable.0
                lfsVersion = lfsAvailable.1
                largeFiles = files
                isLoading = false
            }
        }
    }

    @MainActor
    private func initializeLFS() {
        guard let projectURL = projects.currentProject?.url else { return }
        Task.detached(priority: .userInitiated) {
            _ = try? GitProcessRunner.run(["lfs", "install", "--local"], in: projectURL)
            await MainActor.run {
                refresh()
            }
        }
    }

    private nonisolated static func gitBinaryAvailable(_ name: String) -> (Bool, String?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [name, "version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return (true, String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } catch {}
        return (false, nil)
    }

    /// 递归扫描工作区（跳过 .git 与常见构建目录），返回超过阈值的文件相对路径。
    private nonisolated static func scanLargeFiles(in projectURL: URL, thresholdBytes: Int64) -> [String] {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .isDirectoryKey]
        let skipped: Set<String> = [".git", "node_modules", "DerivedData", ".build", "Pods", "build"]
        var results: [String] = []
        guard let enumerator = fm.enumerator(
            at: projectURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let url as URL in enumerator {
            let last = url.lastPathComponent
            if skipped.contains(last) {
                enumerator.skipDescendants()
                continue
            }
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            if values.isDirectory == true { continue }
            if values.isRegularFile == true, let size = values.fileSize, size > thresholdBytes {
                let relative = url.path.dropFirst(projectURL.path.count + 1)
                results.append(String(relative))
                if results.count >= 200 { break }
            }
        }
        return results
    }

    @LumiTheme private var theme: LumiUITheme
}

private struct GitLFSContentView: View {
    let isLFSAvailable: Bool
    let lfsVersion: String?
    let largeFiles: [String]
    let onInitialize: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive")
                    .foregroundStyle(largeFiles.isEmpty ? theme.textSecondary : theme.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Git LFS")
                        .font(.headline)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                if !isLFSAvailable {
                    AppButton("Install", systemImage: "square.and.arrow.down", style: .secondary, size: .small) {
                        // 引导用户安装 git-lfs。
                    }
                }
            }
            Divider()
            if largeFiles.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.success)
                    Text("No files larger than 50 MB found")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Text("Large file recommendations")
                    .font(.subheadline.weight(.semibold))
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(largeFiles, id: \.self) { file in
                            Text(file)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var statusText: String {
        if isLFSAvailable {
            if let lfsVersion {
                return "Available, \(lfsVersion)"
            }
            return "Available"
        }
        return "git-lfs not detected"
    }

    @LumiTheme private var theme: LumiUITheme
}

/// 项目观察模型：订阅 `ProjectProviding` 事件。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
