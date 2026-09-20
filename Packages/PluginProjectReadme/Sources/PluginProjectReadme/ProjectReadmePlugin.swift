import KernelCore
import ProviderDocsView
import ProviderProjectReadme
import SwiftUI

/// Registers the standalone project README feature with the plugin system.
@MainActor
public final class ProjectReadmePlugin: SuperPlugin {
    public let id = "com.coffic.gitok.plugin.project-readme"
    public let order = 21
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.project-readme",
        name: "Project README",
        description: "Render the current project's README in the worktree overview",
        category: .project,
        stage: .stable,
        policy: .required
    )

    public init() {}

    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { ProjectReadmeAboutView() }
        )
    }

    public func onBoot(kernel: KernelCoreContainer) throws {
        try kernel.registerProvider(
            (any ProjectReadmeProviding).self,
            ProjectReadmeRenderer()
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.unregisterProvider((any ProjectReadmeProviding).self)
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }
}

@MainActor
private final class ProjectReadmeRenderer: ProjectReadmeProviding {
    func makeReadmeView(for projectURL: URL) -> AnyView {
        AnyView(ProjectReadmeView(projectURL: projectURL))
    }
}

private struct ProjectReadmeAboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Project README", systemImage: "doc.text")
                .font(.title2.weight(.semibold))
            Text("When the current project contains a Markdown README, its formatted content appears at the bottom of the clean worktree overview.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
