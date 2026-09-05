import AppKit
import LumiUI
import SwiftUI

private func loc(_ key: String) -> String {
    AboutSettingsLocalization.string(key, bundle: .module)
}

/// 关于应用视图（对齐旧版 AboutView）。
public struct AboutView: View {
    @LumiTheme private var theme

    public init() {}

    public var body: some View {
        AppSettingsContentScaffold(maxContentWidth: 480) {
            VStack(alignment: .center, spacing: 24) {
                VStack(spacing: 12) {
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 5)
                    }
                    Text(appName)
                        .font(.title)
                        .fontWeight(.bold)
                    VStack(spacing: 4) {
                        Text(String(format: loc("Version %@"), appVersion))
                            .font(.body)
                            .foregroundStyle(theme.textSecondary)
                        Text(String(format: loc("Build %@"), appBuild))
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text(loc("About"))
                        .font(.headline)
                    Text(loc("GitOK is a git client built on the Lumi plugin architecture."))
                        .font(.body)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AppSettingSection(title: loc("App Info"), titleAlignment: .leading) {
                    VStack(spacing: 0) {
                        infoRow(title: loc("App Name"), value: appName, icon: "gearshape")
                        Divider()
                        infoRow(title: loc("Version"), value: appVersion, icon: "speaker.wave.2")
                        Divider()
                        infoRow(title: loc("Build"), value: appBuild, icon: "list.bullet")
                        Divider()
                        infoRow(title: loc("Bundle ID"), value: bundleIdentifier, icon: "info.circle")
                    }
                }
            }
        }
        .navigationTitle(Text(loc("About")))
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "GitOK"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "-"
    }

    private func infoRow(title: String, value: String, icon: String) -> some View {
        AppSettingRow(title: title, description: value, icon: icon) {
            EmptyView()
        }
    }
}
