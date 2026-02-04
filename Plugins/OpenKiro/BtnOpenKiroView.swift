import MagicKit
import SwiftUI

struct BtnOpenKiroView: View {
    @EnvironmentObject var g: DataProvider

    static let shared = BtnOpenKiroView()

    private init() {}

    var body: some View {
        if let project = g.project {
            Image.kiroApp
                .resizable()
                .frame(height: 22)
                .frame(width: 22)
                .padding(.horizontal, 5)
                .padding(.vertical, 5)
                .hoverBackground(.regularMaterial)
                .inButtonWithAction {
                    project.url.openInKiro()
                }
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
