import OSLog
import GitOKCoreKit
import SwiftUI

public struct IconDetailLayout: View {
    @Environment(\.gitOKProjectURL) private var projectURL
    @EnvironmentObject var i: IconProvider

    @State private var showWelcome = false
    @State private var icons: [IconData] = []
    @State private var selection: IconData?

    private enum RightPaneTab { case icon, controls }
    @State private var selectedRightPaneTab: RightPaneTab = .controls

    public static let shared = IconDetailLayout()

    public init() {}

    public var body: some View {
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
                            Image.photos.inButtonWithAction {
                                selectedRightPaneTab = .icon
                            }

                            Image.console.inButtonWithAction {
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
                                PaddingControl()
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
        .onChange(of: projectURL) {
            checkWelcome()
            refreshIcons()
        }
        .onChange(of: selection) { _, newValue in
            i.updateCurrentModel(newModel: newValue)
        }
    }

    private func checkWelcome() {
        guard let projectURL else {
            return
        }

        let icons = ProjectIconRepo.getIconData(from: projectURL)
        self.showWelcome = icons.isEmpty
    }

    private func refreshIcons() {
        if let projectURL {
            icons = ProjectIconRepo.getIconData(from: projectURL)
        } else {
            icons = []
        }
    }
}
