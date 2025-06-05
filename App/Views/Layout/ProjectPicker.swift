import SwiftUI
import SwiftData

struct ProjectPicker: View {
    @EnvironmentObject var git: GitProvider

    var body: some View {
        Picker("select_project", selection: $git.project) {
            if git.project == nil {
                Text("select_a_project").tag(nil as Project?)
            }
            ForEach(git.projects, id: \.self) { project in
                Text(project.title).tag(project as Project?)
            }
        }
//        .frame(width: 200)
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(width: 800)
    .frame(height: 1000)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
