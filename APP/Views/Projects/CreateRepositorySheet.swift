import AppKit
import GitCoreKit
import MagicAlert
import GitOKSupportKit
import SwiftUI

struct CreateRepositorySheet: View, SuperLog {
    nonisolated static let emoji = "🆕"
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    @Environment(\.dismiss) private var dismiss

    @State private var parentFolder = FileManager.default.homeDirectoryForCurrentUser
    @State private var repositoryName = ""
    @State private var includeReadme = true
    @State private var gitignoreTemplate = CreateGitignoreTemplate.none
    @State private var licenseTemplate = CreateLicenseTemplate.none
    @State private var createInitialCommit = true
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var trimmedRepositoryName: String {
        repositoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var destinationURL: URL? {
        guard trimmedRepositoryName.isEmpty == false else { return nil }
        return parentFolder.appendingPathComponent(trimmedRepositoryName, isDirectory: true)
    }

    private var destinationState: CloneRepositoryValidation.DestinationState? {
        guard let destinationURL else { return nil }
        let projectExists = data.repoManager.projectRepo.exists(path: destinationURL.path)
        return CloneRepositoryValidation.destinationState(for: destinationURL, projectExists: projectExists)
    }

    private var validationMessage: String? {
        if let repositoryNameMessage = CloneRepositoryValidation.validateRepositoryName(trimmedRepositoryName) {
            return repositoryNameMessage
        }

        guard destinationURL != nil else {
            return "目标路径无效"
        }

        if let destinationState {
            return CloneRepositoryValidation.destinationValidationMessage(for: destinationState)
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            repositorySection
            templateSection
            statusSection
            footer
        }
        .padding(24)
        .frame(width: 560)
    }
}

private extension CreateRepositorySheet {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("新建仓库")
                .font(.title2)
                .fontWeight(.semibold)

            Text("创建一个新的本地 Git 仓库，并自动导入到项目列表。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    var repositorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("本地仓库")
                .font(.headline)

            TextField("仓库名称", text: $repositoryName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text(parentFolder.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button("选择目录") {
                    chooseParentFolder()
                }
            }

            if let destinationURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最终路径")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(destinationURL.path)
                        .font(.caption.monospaced())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            if destinationState == .existingEmptyDirectory {
                Text("目标目录已存在但为空，允许直接初始化为 Git 仓库。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("初始文件")
                .font(.headline)

            Toggle("创建 README.md", isOn: $includeReadme)

            Picker(".gitignore", selection: $gitignoreTemplate) {
                ForEach(CreateGitignoreTemplate.allCases) { template in
                    Text(template.title).tag(template)
                }
            }

            Picker("LICENSE", selection: $licenseTemplate) {
                ForEach(CreateLicenseTemplate.allCases) { template in
                    Text(template.title).tag(template)
                }
            }

            Toggle("创建初始提交", isOn: $createInitialCommit)

            if createInitialCommit {
                Text("初始提交会使用当前仓库或全局 Git 用户配置；如果未配置 user.name/user.email，Git 会返回错误。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("准备创建")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage, errorMessage.isEmpty == false {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    var footer: some View {
        HStack {
            Spacer()

            Button("取消") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .disabled(isCreating)

            Button {
                createRepository()
            } label: {
                if isCreating {
                    ProgressView()
                        .controlSize(.small)
                        .frame(minWidth: 90)
                } else {
                    Text("创建")
                        .frame(minWidth: 90)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCreating || validationMessage != nil)
            .keyboardShortcut(.defaultAction)
        }
    }

    func chooseParentFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            parentFolder = url
        }
    }

    func createRepository() {
        guard let destinationURL, let projectRepo = Optional(data.repoManager.projectRepo) else { return }

        errorMessage = nil
        isCreating = true

        Task { @MainActor in
            data.activityStatus = "创建仓库中…"
        }

        let repositoryName = trimmedRepositoryName
        let options = makeCreateOptions(repositoryName: repositoryName)

        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI.create(at: destinationURL, options: options)

                await MainActor.run {
                    let project = data.addProject(url: destinationURL, using: projectRepo)
                    if let project {
                        vm.setProject(project, reason: "CreateRepository")
                        data.activityStatus = nil
                        isCreating = false
                        alert_info("已创建 \(repositoryName)")
                        dismiss()
                    } else {
                        data.activityStatus = nil
                        isCreating = false
                        errorMessage = "仓库已创建，但导入项目列表失败：\(destinationURL.path)"
                    }
                }
            } catch {
                await MainActor.run {
                    data.activityStatus = nil
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func makeCreateOptions(repositoryName: String) -> GitRepositoryCLI.CreateRepositoryOptions {
        let defaultUserConfig = try? data.repoManager.gitUserConfigRepo.findDefault()

        return GitRepositoryCLI.CreateRepositoryOptions(
            readmeContent: includeReadme ? "# \(repositoryName)\n" : nil,
            gitignoreContent: gitignoreTemplate.content,
            licenseContent: licenseTemplate.content,
            initialCommitMessage: createInitialCommit ? "Initial commit" : nil,
            userName: defaultUserConfig?.name,
            userEmail: defaultUserConfig?.email
        )
    }
}

private enum CreateGitignoreTemplate: String, CaseIterable, Identifiable {
    case none
    case xcode
    case flutter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "不创建"
        case .xcode: return "Xcode"
        case .flutter: return "Flutter"
        }
    }

    var content: String? {
        switch self {
        case .none:
            return nil
        case .xcode:
            return """
            # Xcode
            DerivedData/
            *.xcuserstate
            xcuserdata/
            *.xccheckout
            *.moved-aside
            *.xcscmblueprint

            """
        case .flutter:
            return """
            # Flutter
            .dart_tool/
            .flutter-plugins
            .flutter-plugins-dependencies
            .packages
            Flutter.podspec
            .symlinks/
            pubspec.lock
            .generated/
            ios/Flutter/Flutter.framework
            ios/Flutter/Flutter.podspec
            ios/ServiceDefinitions.json

            """
        }
    }
}

private enum CreateLicenseTemplate: String, CaseIterable, Identifiable {
    case none
    case mit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "不创建"
        case .mit: return "MIT"
        }
    }

    var content: String? {
        switch self {
        case .none:
            return nil
        case .mit:
            return """
            MIT License

            Copyright (c) \(Calendar.current.component(.year, from: Date()))

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.

            """
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}
