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
                VStack {
                    IconBgs()
                        .padding(8)
                        .background(.blue.opacity(0.05))

                    // 图标调整工具
                    IconAdjustments()

                    IconBox()
                        .padding(.horizontal)
                        .padding(.bottom)
                        .background(.green.opacity(0.05))

                    IconMaker()
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
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .setInitialTab(IconPlugin.label)
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
