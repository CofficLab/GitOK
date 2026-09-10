import Foundation
import Testing
@testable import PluginProjectMissing

@Suite("PluginProjectMissing")
@MainActor
struct ProjectMissingPluginTests {

    @Test("plugin metadata conforms to Lumi plugin standards")
    func pluginMetadata() {
        let plugin = ProjectMissingPlugin()
        #expect(plugin.id == "com.coffic.gitok.plugin.project-missing")
        #expect(plugin.metadata.category == .project)
        #expect(plugin.metadata.policy == .required)
    }

    @Test("viewModel detects missing project")
    func viewModelMissingDetection() {
        let viewModel = ProjectMissingViewModel()
        let missingProject = Project(
            url: URL(fileURLWithPath: "/nonexistent/path/to/project"),
            title: "Missing Project"
        )

        viewModel.handleProjectChanged(project: missingProject)
        #expect(viewModel.isMissing == true)
        #expect(viewModel.project?.id == missingProject.id)
    }

    @Test("viewModel clears state when project is nil")
    func viewModelNilProject() {
        let viewModel = ProjectMissingViewModel()

        viewModel.handleProjectChanged(project: nil)
        #expect(viewModel.isMissing == false)
        #expect(viewModel.project == nil)
    }
}
