import SwiftUI
import MagicCore

struct BtnOpenXcodeView: View {
    @EnvironmentObject var g: DataProvider
    
    static let shared = BtnOpenXcodeView()
    
    private init() {}

    var body: some View {
        if let project = g.project {
            project.url
                .makeOpenButton(.xcode, useRealIcon: true)
                .magicShapeVisibility(.onHover)
                .help("用 Xcode 打开")
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
