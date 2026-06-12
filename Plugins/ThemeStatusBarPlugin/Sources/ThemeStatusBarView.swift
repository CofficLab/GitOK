import SwiftUI
import GitOKCoreKit

struct ThemeStatusBarView: View {
    let registry: GitOKUIThemeRegistry
    let selectTheme: (String) -> Void

    init(registry: GitOKUIThemeRegistry, selectTheme: @escaping (String) -> Void) {
        self.registry = registry
        self.selectTheme = selectTheme
    }

    var body: some View {
        StatusBarHoverContainer(
            detailView: ThemePickerPopover(registry: registry, selectTheme: selectTheme),
            popoverWidth: 340,
            id: "gitok-theme-picker"
        ) {
            AppStatusBarTile(systemImage: "paintbrush") {
                Text(registry.selectedContribution?.compactName ?? "Theme")
                    .lineLimit(1)
            }
        }
        .help("Switch theme")
    }
}
