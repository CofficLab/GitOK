import SwiftUI

struct BtnOpenFinderView: View {
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var vm: ProjectVM
    
    static let shared = BtnOpenFinderView()
    
    private init() {}

    var body: some View {
        if let project = vm.project {
            Image.finderApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .inButtonWithAction {
                    project.url.openInFinder()
                }
                .help("在Finder中打开")
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
