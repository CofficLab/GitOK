import GitOKUI
import SwiftUI

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
            HStack(spacing: 4) {
                Image(systemName: "paintbrush")
                    .font(.system(size: 11))

                Text(registry.selectedContribution?.compactName ?? "Theme")
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .help("Switch theme")
    }
}
