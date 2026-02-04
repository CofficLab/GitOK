import SwiftUI

struct BtnOpenCursorView: View {
    @EnvironmentObject var g: DataProvider

    static let shared = BtnOpenCursorView()

    private init() {}

    var body: some View {
        if let project = g.project {
            Image.cursorApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .inButtonWithAction {
                    project.url.openInCursor()
                }
                .help("用 Cursor 打开")
                .toolbarButtonStyle()
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
