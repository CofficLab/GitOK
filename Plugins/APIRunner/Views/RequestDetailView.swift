import SwiftUI

struct RequestDetailView: View {
    @Binding var request: APIRequest
    @EnvironmentObject var apiProvider: APIProvider
    @State private var isEditing = false
    @State private var showErrorDetails = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(request.name)
                    .font(.headline)
                Spacer()
                Button("Edit") { isEditing = true }
            }
            
            HStack {
                Text(request.method.rawValue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text(request.url)
                    .textSelection(.enabled)
            }
            
            if !request.headers.isEmpty {
                GroupBox("Headers") {
                    ForEach(request.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .bold()
                            Text(": ")
                            Text(value)
                        }
                    }
                }
            }
            
            if let body = request.body {
                GroupBox("Body") {
                    Text(body)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            if let error = apiProvider.lastError {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Request Failed")
                                .foregroundColor(.red)
                                .font(.headline)
                            Spacer()
                            Button(action: { showErrorDetails.toggle() }) {
                                Image(systemName: showErrorDetails ? "chevron.up" : "chevron.down")
                            }
                        }
                        
                        if showErrorDetails {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Error Type:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(describing: type(of: error)))
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                
                                Text("Description:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                Text(error.localizedDescription)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                
                                if let nsError = error as? NSError {
                                    Text("Error Code: \(nsError.code)")
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                        .padding(.top, 4)
                                    
                                    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                                        Text("Underlying Error:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 4)
                                        Text(underlyingError.localizedDescription)
                                            .font(.system(.body, design: .monospaced))
                                            .textSelection(.enabled)
                                    }
                                    
                                    if !nsError.userInfo.isEmpty {
                                        Text("User Info:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 4)
                                        ForEach(Array(nsError.userInfo.keys), id: \.self) { key in
                                            if let value = nsError.userInfo[key] {
                                                HStack(alignment: .top) {
                                                    Text(key)
                                                        .font(.system(.caption, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                    Text(": ")
                                                    Text(String(describing: value))
                                                        .font(.system(.caption, design: .monospaced))
                                                }
                                                .textSelection(.enabled)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(8)
                }
            }
            
            HStack {
                Button(action: sendRequest) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send Request")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiProvider.isLoading)
                
                if apiProvider.isLoading {
                    ProgressView()
                        .padding(.leading)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditRequestView(request: $request)
        }
    }
    
    private func sendRequest() {
        Task {
            do {
                _ = try await apiProvider.sendRequest(request)
            } catch {
                print("Request failed: \(error)")
                // 错误已经在 APIProvider 中设置，会自动显示在界面上
            }
        }
    }
} 
