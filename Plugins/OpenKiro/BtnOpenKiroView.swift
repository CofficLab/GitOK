import MagicKit
import SwiftUI

struct BtnOpenKiroView: View {
    @EnvironmentObject var g: DataProvider

    static let shared = BtnOpenKiroView()

    private init() {}

    var body: some View {
        if let project = g.project {
            project.url
                .makeOpenButton(.kiro, useRealIcon: true)
                .magicShapeVisibility(.onHover)
                .help("用 Kiro 打开")
        }
    }
}

fileprivate extension URL {
    func makeOpenKiroButton() -> some View {
        Button(action: {
            openKiro(url: self)
        }, label: {
            Label(
                title: { Text("用 Kiro 打开") },
                icon: {
                    Image(systemName: "water.waves")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(0.9)
                }
            )
        })
    }

    func openKiro(url: URL) {
        var appURL: URL?
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "dev.kiro.desktop") {
            appURL = url
        } else if FileManager.default.fileExists(atPath: "/Applications/Kiro.app") {
            appURL = URL(fileURLWithPath: "/Applications/Kiro.app")
        } else if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Applications/Kiro.app") {
            appURL = URL(fileURLWithPath: NSHomeDirectory() + "/Applications/Kiro.app")
        }

        if let appURL = appURL {
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 600)
        .frame(height: 600)
}
