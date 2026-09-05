import AppKit
import LumiUI
import SwiftUI

/// 设置窗口侧边栏顶部的 Header：应用 Logo（64×64）+ 名称 + 版本。
///
/// 参照 Lumi 经典视觉（`FactoryCore.SettingsSidebarHeaderView`）设计：
/// 使用 `AppSettingsSidebarHeader` 统一排版，顶部 Logo 由 `PluginSettingView`
/// 直接显示当前宿主 App 的 `AppIcon`，避免把插件贡献的 Logo 当作应用图标。
struct HeaderView: View {
    private let appInfo = AppBundleInfo()

    var body: some View {
        AppSettingsSidebarHeader(
            name: appInfo.name,
            version: appInfo.version,
            build: appInfo.build,
            topSpacing: 22,
            bottomSpacing: 8
        ) {
            HStack {
                Spacer()
                logoView
                    .frame(width: 64, height: 64)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var logoView: some View {
        if let appIcon {
            Image(nsImage: appIcon)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
        }
    }

    private var appIcon: NSImage? {
        if let appIcon = NSImage(named: "AppIcon") {
            return appIcon
        }

        let bundlePath = Bundle.main.bundlePath
        guard !bundlePath.isEmpty else { return nil }
        return NSWorkspace.shared.icon(forFile: bundlePath)
    }
}

#Preview("Settings Sidebar Header") {
    HeaderView()
        .frame(width: 220)
        .padding()
}
