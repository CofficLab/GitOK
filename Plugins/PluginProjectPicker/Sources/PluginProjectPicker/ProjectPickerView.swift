import GitOKPluginKit
import ProjectRulesKit
import SwiftUI

struct ProjectPickerView: View {
    @Environment(\.gitOKProjects) private var projects
    @Environment(\.gitOKSelectedProjectURL) private var selectedProjectURL
    @Environment(\.gitOKSidebarVisible) private var isSidebarVisible
    @Environment(\.gitOKProjectSelectionHandler) private var selectProject

    @State private var selection: URL?

    var body: some View {
        Group {
            if !isSidebarVisible {
                Picker(PluginProjectPickerLocalization.string("Select Project"), selection: $selection) {
                    if selection == nil {
                        Text(PluginProjectPickerLocalization.string("Select Project"))
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
            }
        }
        .onAppear {
            selection = selectedProjectURL
        }
    }
}
