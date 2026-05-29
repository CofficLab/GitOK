import SwiftUI

struct BtnOpenCursorView: View {
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var vm: ProjectVM

    static let shared = BtnOpenCursorView()

    private init() {}

    var body: some View {
        if let project = vm.project {
            Image.cursorApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .inButtonWithAction {
                    project.url.openInCursor()
                }
                .help(String(localized: "Open in Cursor"))
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
