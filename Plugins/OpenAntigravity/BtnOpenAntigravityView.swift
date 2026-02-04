import MagicKit
import SwiftUI

struct BtnOpenAntigravityView: View {
    @EnvironmentObject var g: DataProvider

    static let shared = BtnOpenAntigravityView()

    private init() {}

    var body: some View {
        if let project = g.project {
            project.url
                .makeOpenButton(.antigravity, useRealIcon: true)
                .help("用 Antigravity 打开")
        }
    }
}

fileprivate extension URL {
    func makeOpenAntigravityButton() -> some View {
        Button(action: {
            openAntigravity(url: self)
        }, label: {
            Label(
                title: { Text("用 Antigravity 打开") },
                icon: {
                    Image(systemName: "paperplane")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(0.9)
                }
            )
        })
    }

    func openAntigravity(url: URL) {
        var appURL: URL?
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.antigravity.app") {
            appURL = url
        } else if FileManager.default.fileExists(atPath: "/Applications/Antigravity.app") {
            appURL = URL(fileURLWithPath: "/Applications/Antigravity.app")
        } else if FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Applications/Antigravity.app") {
            appURL = URL(fileURLWithPath: NSHomeDirectory() + "/Applications/Antigravity.app")
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
