import SwiftUI

struct BtnOpenTerminalView: View {
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let project = g.project {
            project.url
                .makeOpenButton(.terminal, useRealIcon: true)
                .magicShapeVisibility(.onHover)
                .help("在终端打开")
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
