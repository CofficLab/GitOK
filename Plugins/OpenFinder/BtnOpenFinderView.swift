import SwiftUI

struct BtnOpenFinderView: View {
    @EnvironmentObject var g: DataProvider
    
    static let shared = BtnOpenFinderView()
    
    private init() {}

    var body: some View {
        if let project = g.project {
            project.url
                .makeOpenButton(.finder, useRealIcon: true)
                .magicShapeVisibility(.onHover)
                .help("在Finder中打开")
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
