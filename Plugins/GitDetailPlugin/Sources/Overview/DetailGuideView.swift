import AppKit
import GitCoreKit
import GitOKAppCore
import GitOKSupportKit
import GitOKUI
import OSLog
import SwiftUI

struct DetailGuideView: View, SuperLog {
    nonisolated static let emoji = "🧭"
    nonisolated static let verbose = false

    @EnvironmentObject private var data: DataVM
    @EnvironmentObject private var vm: ProjectVM

    let systemImage: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?
    let iconColor: Color?

    @State private var remoteInfo: [GitRemote] = []

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil,
        iconColor: Color? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
        self.iconColor = iconColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.system(size: 64))
                        .foregroundColor(iconColor ?? .gray)

                    Text(title)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)

                    if let subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)

                if let action, let actionLabel {
                    AppButton(
                        LocalizedStringKey(actionLabel),
                        style: .primary,
                        action: action
                    )
                }

                if let project = vm.project {
                    VStack(alignment: .center) {
                        if vm.projectExists {
                            DetailRepositoryInfoView(
                                project: project,
                                remotes: remoteInfo,
                                branch: data.branch
                            )
                            DetailCurrentUserConfigView(project: project)
                            DetailGitUserPresetView()
                            DetailCommitStylePresetView()
                        } else {
                            DetailProjectNotFoundView(project: project)
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 600)
                    .inMagicHStackCenter()
                    .inMagicVStackCenter()
                }

                Spacer()
            }
        }
        .background(Color(.windowBackgroundColor))
        .onAppear(perform: loadRemoteInfo)
        .onChange(of: vm.project?.path) {
            loadRemoteInfo()
        }
        .onProjectGitRefsDidChange { eventInfo in
            guard eventInfo.project.path == vm.project?.path else { return }
            loadRemoteInfo()
        }
    }

    func setIconColor(_ color: Color) -> DetailGuideView {
        DetailGuideView(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            action: action,
            actionLabel: actionLabel,
            iconColor: color
        )
    }

    private func loadRemoteInfo() {
        guard let loadedProject = vm.project else {
            remoteInfo = []
            return
        }

        Task.detached(priority: .utility) {
            do {
                let remotes = try GitRepositoryCLI(repositoryURL: loadedProject.url).remoteList()
                await MainActor.run {
                    remoteInfo = remotes
                }
            } catch {
                let message = error.localizedDescription
                await MainActor.run {
                    remoteInfo = []
                    if Self.verbose {
                        os_log("\(Self.t)❌ Failed to get remote info: \(message)")
                    }
                }
            }
        }
    }
}
