import LumiUI
import ProviderStatusBar
import ProviderTheme
import SwiftUI

/// 状态栏右侧：主题切换入口。
///
/// 订阅 `ThemeProviding` 观察者事件；点击弹出主题选择面板，
/// 列出全部主题供切换（复刻旧版 `PluginThemeStatusBar`）。
struct ThemeStatusBarItem: View {
    let theme: any ThemeProviding
    @StateObject private var observation: ThemeObservationModel
    @State private var isPresented = false

    init(theme: any ThemeProviding) {
        self.theme = theme
        _observation = StateObject(wrappedValue: ThemeObservationModel(theme: theme))
    }

    private var currentThemeName: String {
        if let id = theme.selectedThemeId,
           let current = theme.themes.first(where: { $0.id == id }) {
            return current.compactName
        }
        return StatusBarLocalization.string("Theme", bundle: .module)
    }

    var body: some View {
        AppStatusBarTile(systemImage: "paintbrush", action: {
            isPresented.toggle()
        }) {
            Text(currentThemeName)
                .lineLimit(1)
        }
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            ThemePickerPopover(theme: theme)
        }
        .help(StatusBarLocalization.string("Switch theme", bundle: .module))
    }
}

/// 主题选择面板：列出全部主题，点击切换。
private struct ThemePickerPopover: View {
    let theme: any ThemeProviding
    @State private var selectedID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(theme.themes) { item in
                Button {
                    try? theme.selectTheme(id: item.id)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: item.iconName)
                            .frame(width: 16)
                        Text(item.displayName)
                        Spacer()
                        if item.id == selectedID {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 240)
        .onAppear {
            selectedID = theme.selectedThemeId ?? theme.themes.first?.id
        }
        .onReceive(observation.$revision) { _ in
            selectedID = theme.selectedThemeId
        }
    }

    @StateObject private var observation: ThemeObservationModel

    init(theme: any ThemeProviding) {
        self.theme = theme
        _observation = StateObject(wrappedValue: ThemeObservationModel(theme: theme))
    }
}

/// 主题观察模型：订阅 `ThemeProviding` 观察者事件，
/// 把变化转成 `@Published revision` 以驱动 SwiftUI 视图重算。
@MainActor
final class ThemeObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ThemeProvidingObserverHandle)?

    init(theme: any ThemeProviding) {
        handle = theme.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
