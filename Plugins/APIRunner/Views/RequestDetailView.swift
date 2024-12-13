import SwiftUI

struct RequestDetailView: View {
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
            .frame(minHeight: 40)
            .frame(maxHeight: 60)
            .layoutPriority(1)

            TabView(selection: $selectedTab) {
                // Params
                GroupBox {
                    ParametersView()
                }
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

                if let size = response?.responseSize {
                    Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
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
                    ResponseBodyView(response: response)
                case 1: // Cookies
                    CookiesView(cookies: response?.cookies ?? [])
                case 2: // Headers
                    HeadersView(headers: response?.headers ?? [:])
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

// 响应体视图
private struct ResponseBodyView: View {
    let response: APIResponse?
    @State private var viewMode: ViewMode = .pretty

    enum ViewMode {
        case pretty, raw, preview, visualize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("View Mode", selection: $viewMode) {
                    Text("Pretty").tag(ViewMode.pretty)
                    Text("Raw").tag(ViewMode.raw)
                    Text("Preview").tag(ViewMode.preview)
                    Text("Visualize").tag(ViewMode.visualize)
                }
                .pickerStyle(.segmented)

                Spacer()

                if let mimeType = response?.mimeType {
                    Text(mimeType)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

            if let body = response?.body {
                Text(body)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }
}

// Cookies 视图
private struct CookiesView: View {
    let cookies: [HTTPCookie]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(cookies, id: \.name) { cookie in
                VStack(alignment: .leading, spacing: 4) {
                    Text(cookie.name)
                        .font(.headline)
                    Text(cookie.value)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    HStack {
                        Label(cookie.domain, systemImage: "globe")
                        Label(cookie.path, systemImage: "folder")
                        if cookie.isSecure {
                            Label("Secure", systemImage: "lock")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Divider()
            }
        }
    }
}

// Headers 视图
private struct HeadersView: View {
    let headers: [String: String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                VStack(alignment: .leading) {
                    Text(key)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                Divider()
            }
        }
    }
}

// Console 视图
private struct ConsoleView: View {
    let logs: [APIResponse.LogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(logs, id: \.timestamp) { log in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(logLevelColor(log.level))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.message)
                            .textSelection(.enabled)
                        Text(log.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Divider()
            }
        }
    }

    private func logLevelColor(_ level: APIResponse.LogEntry.LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .red
        case .debug: return .gray
        }
    }
}

// Performance 视图
private struct PerformanceView: View {
    let response: APIResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TimelineView(response: response)

            GroupBox("Timing Breakdown") {
                VStack(alignment: .leading, spacing: 8) {
                    TimingRow(label: "DNS Lookup", value: response?.dnsLookupTime)
                    TimingRow(label: "TCP Connection", value: response?.tcpConnectionTime)
                    TimingRow(label: "TLS Handshake", value: response?.tlsHandshakeTime)
                    TimingRow(label: "Time to First Byte", value: response?.timeToFirstByte)
                    TimingRow(label: "Total Duration", value: response?.duration)
                }
                .padding()
            }
        }
    }
}

private struct TimingRow: View {
    let label: String
    let value: TimeInterval?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if let value = value {
                Text(String(format: "%.2fms", value * 1000))
                    .monospacedDigit()
            } else {
                Text("N/A")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Security 视图
private struct SecurityView: View {
    let tlsInfo: APIResponse.TLSInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let tlsInfo = tlsInfo {
                GroupBox("TLS/SSL Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Protocol", value: tlsInfo.tlsProtocol)
                        InfoRow(label: "Cipher Suite", value: tlsInfo.cipherSuite)
                        InfoRow(label: "Certificate Expiration", value: tlsInfo.certificateExpirationDate.formatted())
                    }
                    .padding()
                }

                GroupBox("Certificate Chain") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(tlsInfo.certificateChain, id: \.self) { cert in
                                Text(cert)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .padding()
                }
            } else {
                Text("No TLS/SSL information available")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Network 视图
private struct NetworkView: View {
    let connectionInfo: APIResponse.ConnectionInfo?
    let redirectChain: [APIResponse.RedirectInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let info = connectionInfo {
                GroupBox("Connection Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Local IP", value: info.localIP)
                        InfoRow(label: "Remote IP", value: info.remoteIP)
                        InfoRow(label: "Remote Port", value: String(info.remotePort))
                    }
                    .padding()
                }
            }

            if !redirectChain.isEmpty {
                GroupBox("Redirect Chain") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(redirectChain, id: \.timestamp) { redirect in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(redirect.statusCode)")
                                    .font(.headline)
                                Text(redirect.sourceURL.absoluteString)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                Text(redirect.destinationURL.absoluteString)
                                    .foregroundColor(.blue)
                                Text(redirect.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if redirect.timestamp != redirectChain.last?.timestamp {
                                Divider()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .textSelection(.enabled)
        }
    }
}

private struct TimelineView: View {
    let response: APIResponse?

    var body: some View {
        GroupBox("Request Timeline") {
            // 这里可以添加一个可视化的时间轴
            Text("Timeline visualization coming soon")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 1200)
        .frame(height: 800)
}
