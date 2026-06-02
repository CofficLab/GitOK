import GitOKCoreKit
import ProjectRulesKit
import SwiftUI

struct ProjectPickerView: View {
    let projects: [GitOKProjectSummary]
    let selectedProjectURL: URL?
    let selectProject: (URL) -> Void

    @State private var selection: URL?

    init(
        projects: [GitOKProjectSummary],
        selectedProjectURL: URL?,
        selectProject: @escaping (URL) -> Void
    ) {
        self.projects = projects
        self.selectedProjectURL = selectedProjectURL
        self.selectProject = selectProject
    }

    var body: some View {
        Picker(ProjectPickerPluginLocalization.string("Select Project"), selection: $selection) {
            if selection == nil {
                Text(ProjectPickerPluginLocalization.string("Select Project"))
                    .tag(nil as URL?)
            }

            ForEach(projects) { project in
                Text(project.title)
                    .tag(project.url as URL?)
            }
        }
        .onChange(of: selection) { _, newValue in
            if ProjectPickerSelectionRules.shouldApplySelectionChange(
                newSelection: newValue,
                currentProject: selectedProjectURL
            ), let newValue {
                selectProject(newValue)
            }
        }
        .onChange(of: selectedProjectURL) { _, newValue in
            selection = ProjectPickerSelectionRules.syncedSelection(
                currentSelection: selection,
                currentProject: newValue
            )
        }
        .onAppear {
            selection = selectedProjectURL
        }
    }
}
