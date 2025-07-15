import OSLog
import SwiftUI

struct DetailIcon: View {
    @EnvironmentObject var i: IconProvider
    @EnvironmentObject var g: DataProvider
    @State private var showWelcome = false

    static let shared = DetailIcon()

    var body: some View {
        ZStack {
            if showWelcome {
                WelcomeView()
            } else {
                VStack {
                    IconTopBar()

                    GroupBox {
                        IconMaker()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
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

        let icons = try? project.getIcons()
        if icons == nil || icons?.isEmpty == true {
            self.showWelcome = true
        } else {
            self.showWelcome = false
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
