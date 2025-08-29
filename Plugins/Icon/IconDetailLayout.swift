import OSLog
import SwiftUI

struct IconDetailLayout: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var g: DataProvider
    @State private var showWelcome = false
    @State private var icons: [IconData] = []
    @State private var selection: IconData?

    static let shared = IconDetailLayout()

    var body: some View {
        ZStack {
            if showWelcome {
                IconWelcomeView()
            } else {
                HSplitView {
                    VStack {
                        IconTabsBar(icons: icons, selection: $selection)
                            .background(.gray.opacity(0.1))

                        IconMaker()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                            .background(.orange.opacity(0.1))
                    }

                    VStack {
                        IconBox()

                        VStack(spacing: 4) {
                            DownloadButtons()
                            IconBgs()
                            OpacityControl()
                            ScaleControl()
                            CornerRadiusControl()
                        }.padding()
                    }
                }
                .background(.cyan.opacity(0.05))
            }
        }
        .onAppear {
            checkWelcome()
            refreshIcons()
            selection = icons.first
        }
        .onNotification(.iconDidSave, perform: { _ in
            self.showWelcome = false
            let selectedPath = selection?.path
            refreshIcons()
            if let selectedPath = selectedPath {
                selection = icons.first(where: { $0.path == selectedPath })
            } else {
                selection = icons.first
            }
        })
        .onNotification(.iconDidDelete, perform: { _ in
            checkWelcome()
            refreshIcons()
        })
        .onChange(of: g.project) {
            checkWelcome()
            refreshIcons()
        }
        .onChange(of: selection) { _, newValue in
            i.updateCurrentModel(newModel: newValue)
        }
    }

    private func checkWelcome() {
        guard let project = g.project else {
            return
        }

        let icons = ProjectIconRepo.getIconData(from: project)
        self.showWelcome = icons.isEmpty
    }

    private func refreshIcons() {
        if let project = g.project {
            icons = ProjectIconRepo.getIconData(from: project)
        } else {
            icons = []
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 900)
    .frame(height: 900)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 800)
    .frame(height: 1200)
}
