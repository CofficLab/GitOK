import OSLog
import SwiftUI

struct IconDetailLayout: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var g: DataProvider
    @State private var showWelcome = false

    static let shared = IconDetailLayout()

    var body: some View {
        ZStack {
            if showWelcome {
                IconWelcomeView()
            } else {
                VStack(spacing: 0) {
                    IconBgs()
                        .background(.blue.opacity(0.05))

                    // 图标调整工具
                    HStack(spacing: 20) {
                        OpacityControl()
                        ScaleControl()
                        CornerRadiusControl()
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.05))

                    IconBox()
                        .background(.green.opacity(0.05))

                    HStack(spacing: 0) {
                        IconMaker()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                            .background(.orange.opacity(0.1))

                        // 右侧功能区域
                        VStack(spacing: 16) {
                            // 自定义图片按钮
                            CustomImageButton()
                            
                            // 下载区域
                            DownloadButtons()
                                .background(.red.opacity(0.05))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(.purple.opacity(0.05))
                    }
                    .background(.cyan.opacity(0.05))
                }
            }
        }
        .onAppear {
            checkWelcome()
        }
        .onNotification(.iconDidSave, perform: { _ in
            self.showWelcome = false
        })
        .onNotification(.iconDidDelete, perform: { _ in
            checkWelcome()
        })
        .onChange(of: g.project) {
            checkWelcome()
        }
    }

    private func checkWelcome() {
        guard let project = g.project else {
            return
        }

        let icons = ProjectIconRepo.getIconData(from: project)
        self.showWelcome = icons.isEmpty
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
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 800)
    .frame(height: 1200)
}
