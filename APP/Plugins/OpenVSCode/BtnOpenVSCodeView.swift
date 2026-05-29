import SwiftUI

struct BtnOpenVSCodeView: View {
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var vm: ProjectVM

    static let shared = BtnOpenVSCodeView()

    private init() {}

    var body: some View {
        if vm.project != nil {
            Image.vscodeApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .help(String(localized: "Open in VS Code"))
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
