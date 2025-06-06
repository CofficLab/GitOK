import SwiftUI
import SwiftData
import MagicCore

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
        .frame(width: 200)
        .onAppear {
            self.selection = data.project
        }
        .onChange(of: selection) { _, newValue in
            if let newProject = newValue {
                data.setProject(newProject, reason: self.className)
            }
        }
    }
}

#Preview {
    RootView {
        ProjectPickerView()
    }
    .frame(width: 300)
    .frame(height: 100)
}
