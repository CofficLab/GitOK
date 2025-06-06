import SwiftUI
import SwiftData

struct ProjectPicker: View {
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
