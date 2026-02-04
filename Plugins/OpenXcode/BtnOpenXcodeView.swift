import SwiftUI

struct BtnOpenXcodeView: View {
    @EnvironmentObject var g: DataProvider

    static let shared = BtnOpenXcodeView()

    private init() {}

    var body: some View {
        if let project = g.project {
            Image.xcodeApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .padding(.horizontal, 5)
                .padding(.vertical, 5)
                .hoverBackground(.regularMaterial)
                .inButtonWithAction {
                    project.url.openInXcode()
                }
                .help("用 Xcode 打开")
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 600)
        .frame(height: 600)
}

#Preview("App-Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
