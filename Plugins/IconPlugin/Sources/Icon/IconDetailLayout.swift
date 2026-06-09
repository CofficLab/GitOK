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
                            .gitOKUISurface(style: .toolbar, cornerRadius: 0)

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
            refreshIcons(selectFirstWhenNeeded: true)
        }
        .onNotification(.iconDidSave, perform: { _ in
            self.showWelcome = false
            let selectedPath = selection?.path
            refreshIcons(preferredSelectionPath: selectedPath, selectFirstWhenNeeded: true)
        })
        .onNotification(.iconDidDelete, perform: { _ in
            refreshIcons(selectFirstWhenNeeded: true)
        })
        .onChange(of: projectURL) {
            refreshIcons(selectFirstWhenNeeded: true)
        }
        .onChange(of: selection) { _, newValue in
            i.updateCurrentModel(newModel: newValue)
        }
    }

    private func refreshIcons(
        preferredSelectionPath: String? = nil,
        selectFirstWhenNeeded: Bool = false
    ) {
        guard let projectURL else {
            icons = []
            showWelcome = true
            selection = nil
            return
        }

        Task {
            let loadedIcons = await ProjectIconRepo.getIconDataAsync(from: projectURL)

            await MainActor.run {
                guard self.projectURL == projectURL else { return }
                icons = loadedIcons
                showWelcome = loadedIcons.isEmpty

                if let preferredSelectionPath,
                   let preferredSelection = loadedIcons.first(where: { $0.path == preferredSelectionPath }) {
                    selection = preferredSelection
                } else if selectFirstWhenNeeded, selection == nil || loadedIcons.contains(selection!) == false {
                    selection = loadedIcons.first
                }
            }
        }
    }
}
