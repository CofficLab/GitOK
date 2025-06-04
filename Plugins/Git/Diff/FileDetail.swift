import MagicCore
import MagicWeb
import SwiftUI

struct FileDetail: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MessageProvider

    var file: File
    var commit: GitCommit
    @State var view: MagicWebView?
    var debug: Bool = false
    @State var ready: Bool = false

    var body: some View {
        if let view = self.view {
            VStack(spacing: 0) {
                view
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .onChange(of: file, onFileChange)
                    .onChange(of: commit, onCommitChange)
            }
            .if(debug) { view in
                view.border(Color.red, width: 1)
            }
        } else {
            MagicLoading()
                .onAppear {
                    self.view = self.makeView()
                }
        }
    }

    func updateDiffView(reason: String) {
        self.m.append("UpdateDiffView(\(reason))", channel: self.className)

        if commit.isHead {
            self.setTexts(file.lastContent, file.content)
        } else {
            self.setTexts(file.originalContentOfCommit(commit), file.contentOfCommit(commit))
        }
    }

    func makeView() -> MagicWebView {
        #if DEBUG && false
            let view = URL(string: "http://localhost:4173")!.makeWebView(
                onJavaScriptError: { message, line, source in
                    print("检测到 JS 错误！") // 添加调试输出
                    MagicLogger.shared.error("JavaScript错误检测到：")
                    MagicLogger.shared.error("- 消息: \(message)")
                    MagicLogger.shared.error("- 行号: \(line)")
                    MagicLogger.shared.error("- 来源: \(source)")
                },
                onCustomMessage: { message in
                    MagicLogger.shared.debug("收到消息: \(String(describing: message))")
                    // 根据类型进行不同处理
                    if let stringMessage = message as? String, stringMessage == "ready" {
                        MagicLogger.shared.debug("收到eee消息: \(String(describing: message))")
                        self.ready = true
                        self.onJSReady()
                    }
                })
                .showLogView(true)
                .verboseMode(true)
        #else
        let view = WebConfig.htmlFile.makeWebView(
                onJavaScriptError: { message, line, source in
                    print("检测到 JS 错误！") // 添加调试输出
                    MagicLogger.shared.error("JavaScript错误检测到：")
                    MagicLogger.shared.error("- 消息: \(message)")
                    MagicLogger.shared.error("- 行号: \(line)")
                    MagicLogger.shared.error("- 来源: \(source)")
                },
                onCustomMessage: { message in
                    MagicLogger.shared.debug("收到消息: \(String(describing: message))")
                    // 根据类型进行不同处理
                    if let stringMessage = message as? String, stringMessage == "ready" {
                        MagicLogger.shared.debug("收到eee消息: \(String(describing: message))")
                        self.ready = true
                        self.onJSReady()
                    }
                }
            )
            .showLogView(true)
            .verboseMode(true)
        #endif

        return view
    }
}

// MARK: - Event

extension FileDetail {
    func onFileChange() {
        updateDiffView(reason: "File Change")
    }

    func onCommitChange() {
        updateDiffView(reason: "Commit Change")
    }

    func onJSReady() {
        self.m.append("JS Ready", channel: self.className)
        updateDiffView(reason: "JS Ready")
    }
}

// MARK: - API

extension FileDetail {
    func setTexts(_ o: String, _ c: String) {
        self.m.append("setTexts", channel: self.className)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try! encoder.encode([
            "original": o,
            "modified": c,
        ])
        let jsonString = String(data: jsonData, encoding: .utf8)!

        guard let view = self.view else {
            self.m.append("View is nil", channel: self.className)
            return
        }

        view.evaluateJavaScript("window.api.setTextsWithObject(\(jsonString))")
    }

    func setOriginal(_ s: String) {
        guard let view = self.view else {
            self.m.append("View is nil", channel: self.className)
            return
        }
        view.evaluateJavaScript("window.api.setOriginal(`\(s)`)")
    }

    func setModified(_ s: String) {
        guard let view = self.view else {
            self.m.append("View is nil", channel: self.className)
            return
        }
        view.evaluateJavaScript("window.api.setModified(`\(s)`)")
    }

    func getOriginal() {
        guard let view = self.view else {
            self.m.append("View is nil", channel: self.className)
            return
        }
        view.evaluateJavaScript("window.api.original")
    }
}

#Preview("Big Screen") {
    RootView {
        ContentView()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

// MARK: - View Extension

/// 为View添加条件修饰符的扩展
extension View {
    /// 根据条件应用修饰符
    /// - Parameters:
    ///   - condition: 条件
    ///   - transform: 当条件为true时应用的转换
    /// - Returns: 转换后的视图
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
