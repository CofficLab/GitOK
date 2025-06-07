import MagicCore
import SwiftData
import SwiftUI
import OSLog

struct ProjectPickerView: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var app: AppProvider

    @State private var selection: Project?
    
    static let emoji = "💺"
    private let verbose = true
    
    init() {
        if verbose {
            os_log("\(Self.onInit)")
        }
    }

    var body: some View {
        Group {
            if app.sidebarVisibility == false {
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
                    
                    if verbose {
                        os_log("\(self.t)OnAppear, app.sidebarVisibility=\(app.sidebarVisibility)")
                    }
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
            } else {
//                EmptyView().onAppear {
//                    os_log("\(self.t)OnAppear, app.sidebarVisibility=\(app.sidebarVisibility)")
//                }
            }
        }
        .onAppear {
            if verbose {
                os_log("\(self.t)OnAppear, app.sidebarVisibility=\(app.sidebarVisibility)")
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
