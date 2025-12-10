import MagicCore
import SwiftUI

/// LICENSE 状态栏图标：存在 LICENSE 时可点击查看/编辑。
struct LicenseStatusIcon: View, SuperLog {
    @EnvironmentObject var data: DataProvider

    @State private var isSheetPresented = false
    @State private var hasLicense = false

    static let shared = LicenseStatusIcon()

    init() {}

    var body: some View {
        StatusBarTile(icon: "doc.plaintext", onTap: {
            if hasLicense {
                isSheetPresented.toggle()
            } else {
                isSheetPresented.toggle() // 允许创建新文件
            }
        })
        .help(hasLicense ? "查看或编辑 LICENSE" : "未找到 LICENSE，点击创建")
        .sheet(isPresented: $isSheetPresented) {
            LicenseViewer()
                .frame(minWidth: 800, minHeight: 600)
        }
        .onAppear(perform: checkLicenseExistence)
        .onChange(of: data.project, checkLicenseExistence)
    }

    private func checkLicenseExistence() {
        guard let project = data.project else {
            hasLicense = false
            return
        }

        Task {
            do {
                _ = try await project.getLicenseContent()
                await MainActor.run {
                    self.hasLicense = true
                }
            } catch {
                await MainActor.run {
                    self.hasLicense = false
                }
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

