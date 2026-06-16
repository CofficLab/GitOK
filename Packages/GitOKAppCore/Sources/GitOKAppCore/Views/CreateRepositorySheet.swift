import AppKit
import GitCoreKit
import GitOKSupportKit
import GitOKUI
import MagicAlert
import SwiftUI

public struct CreateRepositorySheet: View, SuperLog {
    public nonisolated static let emoji = "🆕"
    public nonisolated static let verbose = false

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
    @State private var destinationState: CloneRepositoryValidation.DestinationState?
    @State private var destinationStatePath: String?
    @State private var isCheckingDestination = false

    public init() {}

    private var trimmedRepositoryName: String {
        repositoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var destinationURL: URL? {
        guard trimmedRepositoryName.isEmpty == false else { return nil }
        return parentFolder.appendingPathComponent(trimmedRepositoryName, isDirectory: true)
    }

    private var validationMessage: String? {
        if trimmedRepositoryName.isEmpty {
            return String(localized: "Please enter repository name", bundle: .module)
        }

        if trimmedRepositoryName == "." || trimmedRepositoryName == ".." {
            return String(localized: "Repository name cannot be . or ..", bundle: .module)
        }

        let invalidCharacters = CharacterSet(charactersIn: "/:\\")
        if trimmedRepositoryName.rangeOfCharacter(from: invalidCharacters) != nil {
            return String(localized: "Repository name cannot contain /, backslash, or :", bundle: .module)
        }

        guard destinationURL != nil else {
            return String(localized: "Target path is invalid", bundle: .module)
        }

        if isCheckingDestination || destinationStatePath != destinationURL?.path {
            return String(localized: "Checking destination…", bundle: .module)
        }

        if let destinationState {
            switch destinationState {
            case .available, .existingEmptyDirectory:
                return nil
            case .existingProject:
                return String(localized: "This directory is already in the project list", bundle: .module)
            case .existingNonEmptyDirectory:
                return String(localized: "Target directory already exists and is not empty. Please change directory or repository name", bundle: .module)
            case .existingFile:
                return String(localized: "Target path already exists as a file", bundle: .module)
            }
        }

        return nil
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            repositorySection
            templateSection
            statusSection
            footer
        }
        .padding(24)
        .frame(width: 560)
        .onAppear {
            refreshDestinationState()
        }
        .onChange(of: repositoryName) { _, _ in
            refreshDestinationState()
        }
        .onChange(of: parentFolder) { _, _ in
            refreshDestinationState()
        }
    }
}

private extension CreateRepositorySheet {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New Repository")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a new local Git repository and automatically import it into the project list.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    var repositorySection: some View {
        AppSettingsSection(title: "Local Repository") {
            AppSettingsRow {
                VStack(alignment: .leading, spacing: 10) {
                    AppInputField("Repository name", text: $repositoryName)

                    HStack {
                        Text(parentFolder.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        AppButton("Choose directory", systemImage: "folder", style: .tonal, size: .small) {
                            chooseParentFolder()
                        }
                    }

                    if let destinationURL {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Final path")
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
                        Text("The target directory already exists but is empty, allowing direct initialization as a Git repository.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    var templateSection: some View {
        AppSettingsSection(title: "Initial Files") {
            AppSettingsRow {
                Toggle("Create README.md", isOn: $includeReadme)
            }

            AppSettingsRow {
                Picker(".gitignore", selection: $gitignoreTemplate) {
                    ForEach(CreateGitignoreTemplate.allCases) { template in
                        Text(template.title).tag(template)
                    }
                }
            }

            AppSettingsRow {
                Picker("LICENSE", selection: $licenseTemplate) {
                    ForEach(CreateLicenseTemplate.allCases) { template in
                        Text(template.title).tag(template)
                    }
                }
            }

            AppSettingsRow {
                Toggle("Create initial commit", isOn: $createInitialCommit)
            }

            if createInitialCommit {
                AppSettingsRow {
                    Text("The initial commit uses the current repository or global Git user configuration; if user.name/user.email is not configured, Git will return an error.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
                Text("Ready to create")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage, errorMessage.isEmpty == false {
                AppErrorBanner(message: errorMessage)
            }
        }
    }

    var footer: some View {
        HStack {
            Spacer()

            AppButton("Cancel", style: .secondary) {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .disabled(isCreating)

            AppButton("Create", systemImage: "plus", style: .primary, isLoading: isCreating) {
                createRepository()
            }
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

    func refreshDestinationState() {
        guard let destinationURL else {
            destinationState = nil
            destinationStatePath = nil
            isCheckingDestination = false
            return
        }

        let destinationPath = destinationURL.path
        let projectExists = data.repoManager.projectRepo.exists(path: destinationPath)
        isCheckingDestination = true

        Task.detached(priority: .utility) {
            let state = CloneRepositoryValidation.destinationState(
                for: destinationURL,
                projectExists: projectExists
            )

            await MainActor.run {
                guard self.destinationURL?.path == destinationPath else { return }
                self.destinationState = state
                self.destinationStatePath = destinationPath
                self.isCheckingDestination = false
            }
        }
    }

    func createRepository() {
        guard let destinationURL, let projectRepo = Optional(data.repoManager.projectRepo) else { return }

        errorMessage = nil
        isCreating = true

        Task { @MainActor in
            data.activityStatus = String(localized: "Creating repository…", bundle: .module)
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
                        alert_info("\(String(localized: "Created", bundle: .module)) \(repositoryName)")
                        dismiss()
                    } else {
                        data.activityStatus = nil
                        isCreating = false
                        errorMessage = "\(String(localized: "Repository created, but failed to import the project list:", bundle: .module)) \(destinationURL.path)"
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
        case .none: return String(localized: "Do not create", bundle: .module)
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
        case .none: return String(localized: "Do not create", bundle: .module)
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

#Preview("Create Repository") {
    CreateRepositorySheet()
        .frame(width: 600, height: 500)
}
