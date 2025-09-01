import OSLog
import SwiftUI
import MagicCore

struct IconDetailLayout: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var g: DataProvider
    
    @State private var showWelcome = false
    @State private var icons: [IconData] = []
    @State private var selection: IconData?

    private enum RightPaneTab { case icon, controls }
    @State private var selectedRightPaneTab: RightPaneTab = .icon

    static let shared = IconDetailLayout()

    var body: some View {
        ZStack {
            if showWelcome {
                IconWelcomeView()
            } else {
                HSplitView {
                    // Left Pane
                    VStack(spacing: 0) {
                        IconTabsBar(icons: icons, selection: $selection)
                            .background(.gray.opacity(0.1))

                        IconMaker().frame(maxHeight: .infinity)
                    }

                    // Right Pane
                    VStack(spacing: 0) {
                        // Custom Tab Bar
                        HStack(spacing: 0) {
                            MagicButton.simple(
                                title: "Icon",
                                style: selectedRightPaneTab == .icon ? .primary : .secondary,
                                size: .auto,
                                shape: .rectangle
                            ) {
                                selectedRightPaneTab = .icon
                            }

                            MagicButton.simple(
                                title: "Controls",
                                style: selectedRightPaneTab == .controls ? .primary : .secondary,
                                size: .auto,
                                shape: .rectangle
                            ) {
                                selectedRightPaneTab = .controls
                            }
                        }
                        .frame(height: 24)
                        .padding(4)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        Divider().padding(.top, 8)

                        // View Content
                        if selectedRightPaneTab == .icon {
                            IconBox()
                        } else {
                            VStack(spacing: 24) {
                                IconBgs(itemSize: 48)
                                OpacityControl()
                                ScaleControl()
                                CornerRadiusControl()
                                Spacer()
                                DownloadButtons()
                            }.padding()
                        }
                    }
                    .frame(minWidth: 300)
                }
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
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 800)
    .frame(height: 800)
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
