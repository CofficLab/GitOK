import SwiftUI

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

                if let size = response?.responseSize {
                    Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
                        .foregroundColor(.secondary)
                }

                if let mimeType = response?.mimeType {
                    Text(mimeType)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()

            // 选项卡
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    let count = getCountForTab(tab)
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
            ScrollView {
                switch selectedTab {
                case 0: // Body
                    ResponseBody(response: response)
                case 1: // Cookies
                    CookiesView(cookies: response?.cookies ?? [])
                case 2: // Headers
                    ResponseHeadersView(headers: response?.headers ?? [:])
                case 3: // Console
                    ConsoleView(logs: response?.logs ?? [])
                case 4: // Performance
                    PerformanceView(response: response)
                case 5: // Security
                    SecurityView(tlsInfo: response?.tlsInfo)
                case 6: // Network
                    NetworkView(
                        connectionInfo: response?.connectionInfo,
                        redirectChain: response?.redirectChain ?? []
                    )
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .background(Color(.controlBackgroundColor))
    }

    private let tabs = ["Body", "Cookies", "Headers", "Console", "Performance", "Security", "Network"]

    private func getCountForTab(_ tab: String) -> Int {
        switch tab {
        case "Headers": return response?.headers.count ?? 0
        case "Cookies": return response?.cookies.count ?? 0
        case "Console": return response?.logs.count ?? 0
        default: return 0
        }
    }

    private var statusColor: Color {
        switch response?.statusCode ?? 0 {
        case 200 ... 299: return .green
        case 300 ... 399: return .blue
        case 400 ... 499: return .orange
        case 500 ... 599: return .red
        default: return .primary
        }
    }
}
