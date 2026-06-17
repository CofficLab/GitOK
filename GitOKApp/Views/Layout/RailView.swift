import GitOKAppCore
import GitOKCoreKit
import SwiftUI

/// 插件 Rail 区域：单个插件占满面板；多个插件纵向堆叠。
struct RailView: View {
    @EnvironmentObject var themeProvider: AppThemeVM

    let items: [GitOKRailItem]
    @Binding var selectedID: String?

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else if items.count == 1, let item = items.first {
            railPanel {
                item.view
            }
        } else {
            railPanel {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index == items.count - 1 {
                            item.view
                                .frame(maxHeight: .infinity)
                        } else {
                            item.view
                        }
                    }
                }
            }
        }
    }

    private func railPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(idealWidth: 240)
            .frame(minWidth: 160)
            .frame(maxWidth: 600)
            .frame(maxHeight: .infinity)
            .background(themeProvider.activeChromeTheme.sidebarBackgroundColor().opacity(0.92))
    }
}
