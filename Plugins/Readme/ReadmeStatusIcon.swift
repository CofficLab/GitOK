import AppKit
import MagicCore
import OSLog
import SwiftUI

struct ReadmeStatusIcon: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    
    @State private var isSheetPresented = false
    @State private var hasReadme = false
    @State var hovered = false
    
    static let shared = ReadmeStatusIcon()
    
    init() {}
    
    var body: some View {
        HStack {            
            Image(systemName: "doc.text.magnifyingglass")
        }
        .help(hasReadme ? "查看 README.md 文档" : "未找到 README.md 文件")
        .onHover(perform: { hovering in
            hovered = hovering
        })
        .onTapGesture {
            if hasReadme {
                isSheetPresented.toggle()
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .sheet(isPresented: $isSheetPresented) {
            ReadmeViewer()
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkReadmeExistence)
        .onChange(of: data.project, checkReadmeExistence)
    }
    
    private func checkReadmeExistence() {
        guard let project = data.project else {
            hasReadme = false
            return
        }
        
        Task {
            do {
                _ = try await project.getReadmeContent()
                await MainActor.run {
                    self.hasReadme = true
                }
            } catch {
                await MainActor.run {
                    self.hasReadme = false
                }
            }
        }
    }
}

#Preview("ReadmeStatusIcon") {
    ReadmeStatusIcon.shared
        .frame(width: 50, height: 30)
} 