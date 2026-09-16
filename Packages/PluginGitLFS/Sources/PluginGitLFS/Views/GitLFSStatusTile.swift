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
    @State private var scanTask: Task<Void, Never>?
    @State private var scanCancellation: GitProcessCancellation?
    @State private var refreshGeneration = 0

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
                        ? GitLFSLocalization.string("LFS status normal", bundle: .module)
                        : String(format: GitLFSLocalization.string("Found %ld large file(s) to track with Git LFS", bundle: .module), largeFiles.count))
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
        .onDisappear(perform: cancelRefresh)
    }

    @MainActor
    private func refresh() {
        refreshGeneration &+= 1
        let generation = refreshGeneration
        cancelRefresh()

        guard let projectURL = projects.currentProject?.url else {
            largeFiles = []
            isLFSAvailable = false
            lfsVersion = nil
            isLoading = false
            return
        }

        let cancellation = GitProcessCancellation()
        scanCancellation = cancellation
        isLoading = true
        scanTask = Task.detached(priority: .utility) {
            let lfsAvailable = Self.gitBinaryAvailable("git-lfs")
            let files = GitLFSLargeFileScanner.scan(
                in: projectURL,
                thresholdBytes: thresholdBytes,
                shouldCancel: { cancellation.isCancelled }
            )
            await MainActor.run {
                guard generation == refreshGeneration, !cancellation.isCancelled else { return }
                isLFSAvailable = lfsAvailable.0
                lfsVersion = lfsAvailable.1
                largeFiles = files
                isLoading = false
                scanTask = nil
                scanCancellation = nil
            }
        }
    }

    @MainActor
    private func cancelRefresh() {
        scanTask?.cancel()
        scanTask = nil
        scanCancellation?.cancel()
        scanCancellation = nil
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
                    Text(GitLFSLocalization.string("Git LFS", bundle: .module))
                        .font(.headline)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                if !isLFSAvailable {
                    AppButton(GitLFSLocalization.string("Install", bundle: .module), systemImage: "square.and.arrow.down", style: .secondary, size: .small) {
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
                    Text(GitLFSLocalization.string("No files larger than 50 MB found", bundle: .module))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Text(GitLFSLocalization.string("Large file recommendations", bundle: .module))
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
                return String(format: GitLFSLocalization.string("Available, %@", bundle: .module), lfsVersion)
            }
            return GitLFSLocalization.string("Available", bundle: .module)
        }
        return GitLFSLocalization.string("git-lfs not detected", bundle: .module)
    }

    @LumiTheme private var theme: LumiUITheme
}

/// 项目观察模型：订阅 `ProjectProviding` 事件。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] event in
            switch event {
            case .selectionChanged, .dataChanged:
                self?.revision += 1
            default:
                break
            }
        }
    }
}
