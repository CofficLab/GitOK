import SwiftUI

struct RequestDetailView: View {
    @Binding var request: APIRequest
    @EnvironmentObject var apiProvider: APIProvider
    @State private var isHeadersExpanded = false
    @State private var selectedTab = 0

    var body: some View {
        VSplitView {
            VStack {
                // 顶部请求信息
                GroupBox {
                    HStack {
                        Menu {
                            ForEach(APIRequest.HTTPMethod.allCases, id: \.self) { method in
                                Button(action: {
                                    request.method = method
                                }) {
                                    Text(method.rawValue)
                                }
                            }
                        } label: {
                            Text(request.method.rawValue)
                                .foregroundColor(.purple)
                                .fontWeight(.semibold)
                                .frame(width: 30)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(4)
                        }.frame(width: 80)

                        TextField("URL", text: $request.url)
                            .textFieldStyle(.plain)
                            .font(.body)

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: sendRequest) {
                                Text("Send")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)

                            Button("Delete") {
                                // 删除逻辑
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                }
                .frame(maxHeight: 60)

                // 请求配置区域
                TabView(selection: $selectedTab) {
                    // Params
                    GroupBox {
                        ParametersView()
                    }
                    .tabItem {
                        Label("Params", systemImage: "list.bullet")
                    }
                    .tag(0)

                    // Headers
                    GroupBox {
                        DisclosureGroup("Headers (\(request.headers.count))", isExpanded: $isHeadersExpanded) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(request.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    VStack(alignment: .leading) {
                                        Text(key)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text(value)
                                            .font(.system(.body, design: .monospaced))
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .tabItem {
                        Label("Headers", systemImage: "list.bullet.indent")
                    }
                    .tag(1)

                    // Body
                    GroupBox {
                        VStack(alignment: .leading) {
                            Picker("Content-Type", selection: .constant(request.contentType)) {
                                ForEach(APIRequest.ContentType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)

                            TextEditor(text: .constant(request.body ?? ""))
                                .font(.system(.body, design: .monospaced))
                                .frame(maxHeight: 300)
                        }
                    }
                    .tabItem {
                        Label("Body", systemImage: "doc.text")
                    }
                    .tag(2)
                }.layoutPriority(1)
            }
            .frame(maxHeight: .infinity)
            .layoutPriority(0.5)

            // 响应区域
            Group {
                if apiProvider.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = apiProvider.lastError {
                    ErrorView(error: error)
                } else if let response = apiProvider.lastResponse {
                    ResponseView(response: response)
                }
            }.frame(maxHeight: .infinity)
            .layoutPriority(1)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }

    private func sendRequest() {
        Task {
            do {
                _ = try await apiProvider.sendRequest(request)
            } catch {
                print("Request failed: \(error)")
            }
        }
    }
}

private struct ParametersView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 参数编辑界面
            Text("Query Parameters")
                .font(.headline)
            // ... 参数列表实现
        }
    }
}

private struct ErrorView: View {
    let error: Error

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.red)
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .textSelection(.enabled)
            }
            .padding()
        }
    }
}

struct ResponseView: View {
    let response: APIResponse?
    @State private var selectedTab = 0
    @State private var isHeadersExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 状态栏
            HStack {
                Text("Status: \(response?.statusCode ?? 0)")
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)

                Text("Duration: \(String(format: "%.2f", response?.duration ?? 0))s")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            
            // 选项卡
            HStack(spacing: 0) {
                ForEach(["Body", "Cookies", "Headers", "Console", "Actual Request"], id: \.self) { tab in
                    let count = tab == "Headers" ? response?.headers.count ?? 0 : 0
                    Button(action: {
                        withAnimation {
                            selectedTab = tabs.firstIndex(of: tab) ?? 0
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(tab)
                            if count > 0 {
                                Text("\(count)")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTab == tabs.firstIndex(of: tab) ? Color.purple.opacity(0.1) : Color.clear)
                        .foregroundColor(selectedTab == tabs.firstIndex(of: tab) ? .purple : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            // 内容区域
            Group {
                switch selectedTab {
                    case 0:
                        // Body
                        ScrollView {
                            if let body = response?.body {
                                HStack {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Button("Pretty") { }
                                                .buttonStyle(.plain)
                                                .foregroundColor(.purple)
                                            Button("Raw") { }
                                                .buttonStyle(.plain)
                                            Button("Preview") { }
                                                .buttonStyle(.plain)
                                            Button("Visualize") { }
                                                .buttonStyle(.plain)
                                            
                                            Menu("HTML") {
                                                // HTML 相关选项
                                            }
                                            
                                            Menu("utf8") {
                                                // 编码相关选项
                                            }
                                        }
                                        .padding(.bottom, 8)
                                        
                                        Text(body)
                                            .font(.system(.body, design: .monospaced))
                                            .textSelection(.enabled)
                                    }
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    case 1:
                        Text("Cookies")
                    case 2:
                        Text("Headers")
                    case 3:
                        Text("Console")
                    case 4:
                        Text("Actual Request")
                    default:
                        EmptyView()
                }
            }
        }
        .background(Color(.controlBackgroundColor))
    }
    
    private let tabs = ["Body", "Cookies", "Headers", "Console", "Actual Request"]
    
    private var statusColor: Color {
        switch response?.statusCode ?? 0 {
        case 200...299: return .green
        case 300...399: return .blue
        case 400...499: return .orange
        case 500...599: return .red
        default: return .primary
        }
    }
}
