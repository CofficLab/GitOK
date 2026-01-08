import AppKit
import MagicKit
import OSLog
import SwiftUI
import MarkdownUI

struct ReadmeViewer: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    @Environment(\.dismiss) private var dismiss
    
    @State private var readmeContent: String = ""
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    
    private let verbose = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("README.md")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let project = data.project {
                            Text(project.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Button("关闭") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )
            
            // 内容区域
            ScrollView {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("正在加载文档...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minHeight: 300)
                } else if hasError || readmeContent.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.below.ecg")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("未找到 README.md 文件")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("当前项目中没有找到 README.md 文件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minHeight: 300)
                } else {
                    ScrollView {
                        Markdown(readmeContent)
                            .markdownTheme(.gitHub)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear(perform: loadReadme)
        .onChange(of: data.project, loadReadme)
    }
    
    private func loadReadme() {
        guard let project = data.project else {
            readmeContent = ""
            isLoading = false
            hasError = true
            return
        }
        
        isLoading = true
        hasError = false
        
        Task {
            do {
                let content = try await project.getReadmeContent()
                await MainActor.run {
                    self.readmeContent = content
                    self.isLoading = false
                    self.hasError = false
                }
            } catch {
                await MainActor.run {
                    self.readmeContent = ""
                    self.isLoading = false
                    self.hasError = true
                }
                
                if verbose {
                    os_log(.info, "\(self.t)No README.md found or error reading: \(error)")
                }
            }
        }
    }
}

#Preview("ReadmeViewer") {
    ReadmeViewer()
        .frame(width: 800, height: 600)
} 
