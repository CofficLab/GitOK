import SwiftUI

struct BtnOpenXcodeView: View {
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var vm: ProjectVM

    static let shared = BtnOpenXcodeView()

    private init() {}

    var body: some View {
        if let project = vm.project {
            Image.xcodeApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .inButtonWithAction {
                    project.url.openInXcode()
                }
                .help(String(localized: "Open in Xcode"))
                .toolbarButtonStyle()
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
