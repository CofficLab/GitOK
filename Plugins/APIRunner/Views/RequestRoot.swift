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
                TextField("Name", text: $request.name)
                    .textFieldStyle(.plain)
                    .font(.body)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)

            // 顶部请求信息
            RequestBar(request: $request)
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
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background.opacity(0.2))
    }
}

#Preview {
    AppPreview()
        .frame(width: 1200)
        .frame(height: 800)
}
