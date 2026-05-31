import GitOKUI
import SwiftUI

struct ThemeStatusBarView: View {
    @EnvironmentObject private var registry: GitOKUIThemeRegistry

    var body: some View {
        StatusBarHoverContainer(
            detailView: ThemePickerPopover(),
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
