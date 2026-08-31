import AppKit
import SwiftUI

public struct SettingsCommand: Commands {
    @Environment(\.openWindow) private var openWindow

    public init() {}

    public var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button(String(localized: "Settings...")) {
                openWindow(id: AppBootstrap.settingsWindowID)
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
