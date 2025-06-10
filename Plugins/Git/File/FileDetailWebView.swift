import AppKit
import MagicCore
import OSLog
import SwiftUI

/// 使用WebView来渲染差异
struct FileDetailWebView: View, SuperLog, SuperEvent, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var data: DataProvider

    @State private var view: MagicWebView?
    @State private var jsReady = false
    @State private var viewReady = false

    static let emoji = "🌍"

    private var verbose = true

    var body: some View {
        VStack(spacing: 0) {
            if let file = data.file {
                // 文件路径显示组件
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text(file.projectPath + "/" + file.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.textBackgroundColor))
            }

            ZStack {
                if let view = self.view {
                    // 必须加载，其内部JS才能加载
                    view
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                        .opacity(self.jsReady && self.viewReady ? 1 : 0)
                }

                if !self.jsReady || !self.viewReady {
                    MagicLoading()
                }
            }
        }
        .onChange(of: data.file, onFileChange)
        .onChange(of: data.commit, onCommitChange)
        .onAppear {
            withAnimation {
                self.view = self.makeView()
            }
        }
        .frame(maxHeight: .infinity)
    }

    func showFirstPage() {
        os_log("\(self.t)Show First Page")
        self.updateDiffView(reason: "ShowFirstPage")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            self.viewReady = true
        })
    }

    func updateDiffView(reason: String) {
        self.m.append("UpdateDiffView(\(reason))", channel: self.className)

        guard let commit = data.commit, let file = data.file else {
            return
        }

        if commit.isHead {
            do {
                self.setTexts(file.lastContent, try file.getContent())
            } catch let error {
                self.m.error(error)
            }
        } else {
            self.setTexts(file.originalContentOfCommit(commit), file.contentOfCommit(commit))
        }
    }

    func makeView() -> MagicWebView {
        if verbose {
            os_log("\(self.t)🔨 MakeView")
        }

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
                    if verbose {
                        os_log("\(self.t)🍋 收到消息: \(String(describing: message))")
                    }
                    // 根据类型进行不同处理
                    if let stringMessage = message as? String, stringMessage == "ready" {
                        self.onJSReady()
                    }
                }
            )
            .showLogView(false)
            .verboseMode(false)
        #endif

        return view
    }
}

// MARK: - Event

extension FileDetailWebView {
    func onFileChange() {
        updateDiffView(reason: "File Change")
    }

    func onCommitChange() {
        updateDiffView(reason: "Commit Change")
    }

    func onJSReady() {
        os_log("\(self.t)JS Ready")
        self.showFirstPage()
        self.jsReady = true
    }
}

// MARK: - API

extension FileDetailWebView {
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

        self.view = view.evaluateJavaScript("window.api.setTextsWithObject(\(jsonString))")
    }
}

#Preview("Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
