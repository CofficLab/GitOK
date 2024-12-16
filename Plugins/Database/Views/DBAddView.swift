import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct DBAddView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dbProvider: DatabaseProvider
    @State private var name = ""
    @State private var type: DatabaseConfig.DatabaseType = .mysql
    
    // MySQL fields
    @State private var host = "127.0.0.1"
    @State private var port = "3306"
    @State private var username = "root"
    @State private var password = ""
    @State private var database = ""
    
    // SQLite fields
    @State private var showingFilePicker = false
    @State private var sqlitePath = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Database Type")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Picker("Type", selection: $type) {
                                Text("MySQL").tag(DatabaseConfig.DatabaseType.mysql)
                                Text("SQLite").tag(DatabaseConfig.DatabaseType.sqlite)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(nsColor: .windowBackgroundColor))
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Database Name")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter database name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(nsColor: .windowBackgroundColor))
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        )
                        
                        if type == .mysql {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("MySQL Configuration")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                CustomTextField(icon: "network", title: "Host", text: $host)
                                CustomTextField(icon: "number", title: "Port", text: $port)
                                CustomTextField(icon: "person", title: "Username", text: $username)
                                CustomTextField(icon: "lock", title: "Password", text: $password, isSecure: true)
                                CustomTextField(icon: "cylinder", title: "Database", text: $database)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(nsColor: .windowBackgroundColor))
                                    .shadow(color: .black.opacity(0.1), radius: 5)
                            )
                        }
                        
                        if type == .sqlite {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SQLite Database File")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { showingFilePicker = true }) {
                                    HStack {
                                        Image(systemName: "doc.badge.plus")
                                        Text(sqlitePath.isEmpty ? "Choose Database File" : sqlitePath)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentColor, lineWidth: 1)
                                    )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(nsColor: .windowBackgroundColor))
                                    .shadow(color: .black.opacity(0.1), radius: 5)
                            )
                        }
                    }
                    .padding()
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
                        withAnimation {
                            addDatabase()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .frame(maxWidth: 600)
        .fileImporter(isPresented: $showingFilePicker,
                     allowedContentTypes: [.sqlite3Database, .database]) { result in
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

struct CustomTextField: View {
    let icon: String
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}

#Preview {
    DBAddView()
        .environmentObject(DatabaseProvider())
} 
