import OSLog
import GitOKCoreKit
import GitOKUI
import SwiftUI

public struct IconDetailLayout: View {
    let projectURL: URL?
    @EnvironmentObject var i: IconProvider

    @State private var showWelcome = false
    @State private var icons: [IconData] = []
    @State private var selection: IconData?

    private enum RightPaneTab { case icon, controls }
    @State private var selectedRightPaneTab: RightPaneTab = .controls

    public static let shared = IconDetailLayout()

    public init(projectURL: URL? = nil) {
        self.projectURL = projectURL
    }

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
                        HStack(spacing: 4) {
                            AppIconButton(
                                systemImage: "photo.on.rectangle",
                                size: .regular,
                                isActive: selectedRightPaneTab == .icon
                            ) {
                                selectedRightPaneTab = .icon
                            }

                            AppIconButton(
                                systemImage: "keyboard",
                                size: .regular,
                                isActive: selectedRightPaneTab == .controls
                            ) {
                                selectedRightPaneTab = .controls
                            }
                        }
                        .padding(4)
                        .gitOKUISurface(style: .subtle, cornerRadius: 8)
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
