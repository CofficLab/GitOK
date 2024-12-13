import MagicKit
import OSLog
import SwiftUI

struct RequestDetailView: View, SuperLog {
    @Binding var request: APIRequest
    @EnvironmentObject var apiProvider: APIProvider
    @State private var isHeadersExpanded = false
    @State private var selectedTab = 0

    var body: some View {
        VSplitView {
            GroupBox {
                TextField("URL", text: $request.name)
                    .textFieldStyle(.plain)
                    .font(.body)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)

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
            .frame(minHeight: 50)
            .frame(maxHeight: 70)
            .layoutPriority(1)

            // 完整链接
            GroupBox {
                HStack {
                    Text(buildFullURL())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(3)
                    Spacer()
                }
            }
            .frame(minHeight: 50)
            .frame(maxHeight: 70)
            .layoutPriority(1)

            TabView(selection: $selectedTab) {
                ParametersView(request: $request)
                    .tabItem {
                        Label("Params", systemImage: "list.bullet")
                    }.tag(0)

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
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 100)
            .layoutPriority(2)

            // 响应区域
            Group {
                if apiProvider.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = apiProvider.lastError {
                    ErrorView(error: error)
                } else if let response = apiProvider.lastResponse {
                    ResponseView(response: response)
                } else {
                    Text("No response").frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity)
            .layoutPriority(3)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background.opacity(0.2))
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

    private func buildFullURL() -> String {
        guard var components = URLComponents(string: request.url) else {
            os_log("\(t) URL解析失败: \(request.url)")
            return request.url
        }

        components.queryItems = request.queryParameters.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        let finalURL = components.string ?? request.url
        return finalURL
    }
}

#Preview {
    AppPreview()
        .frame(width: 1200)
        .frame(height: 800)
}
