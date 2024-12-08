import SwiftUI
import SwiftData

struct ProjectPicker: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var git: GitProvider

    @State var project: Project?

    @Query(sort: Project.orderReverse) var projects: [Project]

    var body: some View {
        Picker("选择项目", selection: $project) {
            if project == nil {
                Text("选择一个项目").tag(nil as Project?)
            }
            ForEach(projects, id: \.self) { project in
                Text(project.title).tag(project as Project?)
            }
        }
        .frame(width: 200)
        .onAppear {
            self.project = git.project
        }
        .onChange(of: git.project) {
            self.project = git.project
        }
        .onChange(of: project) {
            git.setProject(project, reason: "ProjectPicker")
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
