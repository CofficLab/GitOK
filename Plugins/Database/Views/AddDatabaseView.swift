import SwiftUI
import UniformTypeIdentifiers

struct AddDatabaseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dbProvider: DatabaseProvider
    @State private var name = ""
    @State private var type: DatabaseConfig.DatabaseType = .mysql
    
    // MySQL fields
    @State private var host = "localhost"
    @State private var port = "3306"
    @State private var username = ""
    @State private var password = ""
    @State private var database = ""
    
    // SQLite fields
    @State private var showingFilePicker = false
    @State private var sqlitePath = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        Text("MySQL").tag(DatabaseConfig.DatabaseType.mysql)
                        Text("SQLite").tag(DatabaseConfig.DatabaseType.sqlite)
                    }
                } header: {
                    Text("General")
                }
                
                if type == .mysql {
                    Section("MySQL Connection") {
                        TextField("Host", text: $host)
                        TextField("Port", text: $port)
                        TextField("Username", text: $username)
                        TextField("Password", text: $password)
                        TextField("Database", text: $database)
                    }
                } else {
                    Section("SQLite Database") {
                        HStack {
                            Text(sqlitePath.isEmpty ? "No file selected" : sqlitePath)
                                .foregroundColor(sqlitePath.isEmpty ? .secondary : .primary)
                            Spacer()
                            Button("Choose...") {
                                showingFilePicker = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Database")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addDatabase()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.sqlite3Database, .database]
        ) { result in
            switch result {
            case .success(let url):
                sqlitePath = url.path
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
    }
    
    private var isValid: Bool {
        if name.isEmpty { return false }
        
        switch type {
        case .mysql:
            return !host.isEmpty &&
                   !port.isEmpty &&
                   !username.isEmpty &&
                   !password.isEmpty &&
                   !database.isEmpty
        case .sqlite:
            return !sqlitePath.isEmpty
        }
    }
    
    private func addDatabase() {
        let config: DatabaseConfig
        
        switch type {
        case .mysql:
            config = DatabaseConfig.createMySQLConfig(
                name: name,
                host: host,
                port: Int(port) ?? 3306,
                username: username,
                password: password,
                database: database
            )
        case .sqlite:
            config = DatabaseConfig.createSQLiteConfig(
                name: name,
                path: sqlitePath
            )
        }
        
        dbProvider.addConfig(config)
        dismiss()
    }
}

extension UTType {
    static var sqlite3Database: UTType {
        UTType(filenameExtension: "sqlite3") ?? .database
    }
    
    static var database: UTType {
        UTType(filenameExtension: "db") ?? .data
    }
}

#Preview {
    AddDatabaseView()
        .environmentObject(DatabaseProvider())
} 
