import MagicKit
import OSLog
import SwiftUI

struct RequestRoot: View, SuperLog {
    @Binding var request: APIRequest
    @EnvironmentObject var apiProvider: APIProvider
    @State private var isHeadersExpanded = false
    @State private var selectedTab = 0

    var body: some View {
        VStack {
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

            // 中部配置
            TabView(selection: $selectedTab) {
                ParametersView(request: $request).tag(0)
                    .tabItem { Label("Params", systemImage: "list.bullet") }

                RequestHeadersView(request: $request).tag(1)
                    .tabItem { Label("Headers", systemImage: "list.bullet.indent") }

                RequestBodyView(request: $request).tag(2)
                    .tabItem { Label("Body", systemImage: "doc.text") }
            }
            .frame(maxWidth: .infinity)

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
            .frame(maxWidth: .infinity)
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
