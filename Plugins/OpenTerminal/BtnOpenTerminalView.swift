import SwiftUI

struct BtnOpenTerminalView: View {
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let project = g.project {
            Image.terminalApp
                .resizable()
                .frame(height: 16)
                .frame(width: 16)
                .inButtonWithAction {
                    project.url.openInTerminal()
                }
                .help("在终端打开")
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
