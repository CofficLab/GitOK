import MagicKit
import OSLog
import SwiftData
import SwiftUI

struct ProjectPickerView: View, SuperLog {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    @EnvironmentObject var app: AppVM

    @State private var selection: Project?

    static let emoji = "💺"
    static let verbose = false
    static let shared = ProjectPickerView()

    private init() {
        if Self.verbose {
            os_log("\(Self.onInit)")
        }
    }

    var body: some View {
        Group {
            if app.sidebarVisibility == false {
                Picker("选择项目", selection: $selection) {
                    if selection == nil {
                        Text("请选择项目").tag(nil as Project?)
                    }
                    ForEach(data.projects, id: \.url) { project in
                        Text(project.title).tag(project as Project?)
                    }
                }
                .onChange(of: selection) { _, newValue in
                    if ProjectPickerSelectionRules.shouldApplySelectionChange(
                        newSelection: newValue,
                        currentProject: vm.project
                    ), let newProject = newValue {
                        vm.setProject(newProject, reason: self.className)
                    }
                }
                .onChange(of: vm.project, {
                    self.selection = ProjectPickerSelectionRules.syncedSelection(
                        currentSelection: selection,
                        currentProject: vm.project
                    )
                })
            }
        }
        .onAppear {
            self.selection = vm.project
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentLayout()
    })
    .frame(width: 800, height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
