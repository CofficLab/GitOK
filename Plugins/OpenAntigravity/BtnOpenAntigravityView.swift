import MagicKit
import SwiftUI

struct BtnOpenAntigravityView: View {
    @EnvironmentObject var g: DataProvider

    static let shared = BtnOpenAntigravityView()

    private init() {}

    var body: some View {
        if let project = g.project {
            Image.antigravityApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .inButtonWithAction {
                    project.url.openInAntigravity()
                }
                .help("用 Antigravity 打开")
                .toolbarButtonStyle()
        }
    }
}

// MARK: - Preview

#Preview("App") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 600)
}
