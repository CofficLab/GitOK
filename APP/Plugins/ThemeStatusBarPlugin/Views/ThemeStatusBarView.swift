import SwiftUI

struct ThemeStatusBarView: View {
    @EnvironmentObject private var themeProvider: AppThemeVM
    @State private var isPresented = false

    var body: some View {
        StatusBarTile(icon: "paintbrush", onTap: {
            isPresented.toggle()
        }) {
            Text(themeProvider.currentTheme?.compactName ?? "Theme")
                .lineLimit(1)
        }
        .help("Switch theme")
        .popover(isPresented: $isPresented) {
            ThemePickerPopover(isPresented: $isPresented)
                .frame(width: 340, height: 420)
        }
    }
}
