import SwiftUI

struct BtnOpenTraeView: View {
    @EnvironmentObject var g: DataProvider

    static let shared = BtnOpenTraeView()

    private init() {}

    var body: some View {
        if let project = g.project {
            Image.traeApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .hoverScale(105)
                .padding(.horizontal, 5)
                .inButtonWithAction {
                    project.url.openInTrae()
                }
                .help("用 Trae 打开")
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
//        .hideProjectActions()
        .inRootView()
        .frame(width: 600)
        .frame(height: 600)
}

#Preview("App-Big Screen") {
    ContentLayout()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
