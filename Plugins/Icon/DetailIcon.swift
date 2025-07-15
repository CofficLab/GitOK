import MagicCore
import OSLog
import SwiftUI

struct DetailIcon: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var i: IconProvider

    let emoji = "🦁"

    @State var icon: IconModel?
    @State var backgroundId: String = "4"

    var body: some View {
        VStack {
            if let iconBinding = Binding($icon) {
                let icon = iconBinding.wrappedValue
                VStack {
                    IconTopBar()
                    GeometryReader { geo in
                        HStack {
                            IconMaker()
                                .tag(Optional(icon))
                                .tabItem { Text(icon.title) }
                        }
                    }
                    .padding()
                    .onChange(of: backgroundId) {
                        do {
                            try self.icon?.updateBackgroundId(backgroundId)
                        } catch {
                            m.error(error.localizedDescription)
                        }
                    }
                }
            } else {
                Text("没有可用的图标")
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            do {
                self.icon = try i.getIcon()
            } catch {
                os_log(.error, "\(self.t)Error getting icon: \(error.localizedDescription)")
                os_log(.error, "  ⚠️ \(error)")
                m.error(error.localizedDescription)
            }
        }
//        .onReceive(app.events.did(.iconDidSave)) { _ in
//            do {
//                self.icon = try i.getIcon()
//            } catch {
//                os_log(.error, "\(self.t)Error getting icon: \(error.localizedDescription)")
//                m.error(error.localizedDescription)
//            }
//        }
        .onChange(of: i.iconURL, {
            do {
                self.icon = try i.getIcon()
            } catch {
                os_log(.error, "\(self.t)Error getting icon: \(error)")
                m.error(error.localizedDescription)
            }
        })
        .onChange(of: self.icon, {
            guard let icon = self.icon else {
                return
            }

            do {
                try icon.saveToDisk()
            } catch {
                m.error(error.localizedDescription)
            }

            if let path = icon.path {
                i.setIconURL(URL(filePath: path), reason: "DetailIcon")
            }
        })
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
