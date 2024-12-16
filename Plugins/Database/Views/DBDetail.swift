import SwiftUI

struct DBDetail: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var dbProvider: DatabaseProvider
    @State private var showingAddConfig = false
    @State private var showingDeleteAlert = false
    @State private var configToDelete: DatabaseConfig?

    var body: some View {
        Group {
            if let project = g.project {
                ZStack {
                    if let selectedId = dbProvider.selectedConfigId {
                        DBContent()
                            .frame(maxWidth: .infinity)
                    } else {
                        DBEmptyView()
                    }
                }
                .sheet(isPresented: $showingAddConfig) {
                    AddDatabaseView()
                }
                .alert("Delete Configuration",
                       isPresented: $showingDeleteAlert,
                       presenting: configToDelete) { config in
                    Button("Delete", role: .destructive) {
                        dbProvider.removeConfig(id: config.id)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { config in
                    Text("Are you sure you want to delete '\(config.name)'? This action cannot be undone.")
                }
                .frame(maxWidth: .infinity)
            } else {
                Text(LocalizedStringKey("select_project"))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if let project = g.project {
                dbProvider.loadConfigs(from: project)
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
