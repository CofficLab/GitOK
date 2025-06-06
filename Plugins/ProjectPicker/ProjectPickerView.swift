import MagicCore
import SwiftData
import SwiftUI

struct ProjectPickerView: View, SuperLog {
    @EnvironmentObject var data: DataProvider

    @State private var selection: Project?

    var body: some View {
        Picker("select_project", selection: $selection) {
            if selection == nil {
                Text("select_a_project").tag(nil as Project?)
            }
            ForEach(data.projects, id: \.url) { project in
                Text(project.title).tag(project as Project?)
            }
        }
        .onAppear {
            self.selection = data.project
        }
        .onChange(of: selection) { _, newValue in
            if let newProject = newValue, newValue != data.project {
                data.setProject(newProject, reason: self.className)
            }
        }
        .onChange(of: data.project, {
            if let project = data.project, project != selection {
                self.selection = project
            }
        })
    }
}

#Preview {
    RootView {
        ProjectPickerView()
    }
    .frame(width: 300)
    .frame(height: 100)
}
