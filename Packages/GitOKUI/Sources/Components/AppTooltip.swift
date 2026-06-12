import SwiftUI

public extension View {
    func gitOKUITooltip(_ text: LocalizedStringKey) -> some View {
        help(text)
    }

    func gitOKUITooltip(_ text: LocalizedStringKey, shortcut: KeyboardShortcut?) -> some View {
        Group {
            if let shortcut {
                let shortcutStr = shortcutText(shortcut)
                let tooltipText = Text(text) + Text(" (\(shortcutStr))")
                help(tooltipText)
            } else {
                help(text)
            }
        }
    }

    private func shortcutText(_ shortcut: KeyboardShortcut) -> String {
        var parts: [String] = []

        if shortcut.modifiers.contains(.command) { parts.append("⌘") }
        if shortcut.modifiers.contains(.option) { parts.append("⌥") }
        if shortcut.modifiers.contains(.control) { parts.append("⌃") }
        if shortcut.modifiers.contains(.shift) { parts.append("⇧") }

        parts.append(shortcut.key)

        return parts.joined()
    }
}

extension KeyboardShortcut {
    var key: String {
        switch self {
        case .defaultAction: "↩"
        case .cancelAction: "⌘."
        default: ""
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Hover me")
            .gitOKUITooltip("Simple tooltip")
        Text("With shortcut")
            .gitOKUITooltip("Save file", shortcut: .init("s", modifiers: .command))
    }
    .padding()
    .frame(width: 300)
    .background(Color.gray.opacity(0.15))
}
