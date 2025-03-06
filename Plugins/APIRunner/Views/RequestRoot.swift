import MagicKit
import OSLog
import SwiftUI

struct RequestRoot: View, SuperLog {
    @Binding var request: APIRequest
    @EnvironmentObject var apiProvider: APIProvider
    @State private var isHeadersExpanded = false
    @State private var selectedTab = 0
    @State private var tabHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            GroupBox {
                TextField("Name", text: $request.name)
                    .textFieldStyle(.plain)
                    .font(.body)
            }
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)

            // 顶部请求信息
            RequestBar(request: $request)
                .padding(.bottom, 10)

            // 中部配置
            TabView(selection: $selectedTab) {
                RequestParameters(request: $request)
                    .tag(0)
                    .tabItem { Label("Params", systemImage: "list.bullet") }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: TabHeightPreferenceKey.self, value: geo.size.height)
                    })

                RequestHeaders(request: $request)
                    .tag(1)
                    .tabItem { Label("Headers", systemImage: "list.bullet.indent") }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: TabHeightPreferenceKey.self, value: geo.size.height)
                    })

                RequestBodyView(request: $request)
                    .tag(2)
                    .tabItem { Label("Body", systemImage: "doc.text") }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: TabHeightPreferenceKey.self, value: geo.size.height)
                    })
            }
            .padding(.bottom, 20)
            .frame(height: tabHeight)
            .onPreferenceChange(TabHeightPreferenceKey.self) { height in
                tabHeight = height + 30
            }

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

// 首先定义一个 PreferenceKey 来传递高度信息
struct TabHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
