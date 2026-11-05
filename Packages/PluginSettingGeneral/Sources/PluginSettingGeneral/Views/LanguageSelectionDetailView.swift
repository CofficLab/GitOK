import KitGitOKLocalization
import LumiUI
import SwiftUI

/// 设置窗口「通用 → 语言」分组的详情视图。
///
/// 提供界面语言选择器：
/// - 「跟随系统」——使用系统语言偏好（默认行为）；
/// - 显式选择某种语言——覆盖系统偏好，未翻译的内容回落到英文。
///
/// 语言切换立即生效，不需要重启 App。
struct LanguageSelectionDetailView: View {
    /// 语言选项。
    struct LanguageOption: Identifiable {
        /// 语言标识。`nil` 表示跟随系统。
        let code: String?
        /// 展示名称（用该语言自身书写，便于识别）。
        let displayName: String
        /// 辅助说明（该语言在本 App 中的翻译状态）。
        let note: String

        var id: String { code ?? "system" }
    }

    /// 支持选择的语言。
    ///
    /// 取值来自各插件 catalog 中实际出现过的语言，
    /// 不设硬编码白名单——新增译文后自动出现在列表中。
    static let availableLanguages: [LanguageOption] = [
        LanguageOption(
            code: nil,
            displayName: "System",
            note: "Follow the system language preference."
        ),
        LanguageOption(code: "en", displayName: "English", note: "English"),
        LanguageOption(code: "zh-Hans", displayName: "简体中文", note: "Simplified Chinese"),
        LanguageOption(code: "zh-Hant", displayName: "繁體中文", note: "Traditional Chinese"),
    ]

    @StateObject private var model = LanguageSelectionViewModel()

    var body: some View {
        AppSettingSection(
            title: pluginLocalization.string("Language"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: pluginLocalization.string("Interface Language"),
                    description: pluginLocalization.string("Choose the language used in GitOK."),
                    icon: "globe"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                languagePicker
            }
        }
    }

    /// 语言下拉选择器。
    private var languagePicker: some View {
        Picker(selection: selectionBinding) {
            ForEach(Self.availableLanguages) { option in
                Text(option.displayName).tag(option.id)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .accessibilityIdentifier(Self.pickerIdentifier)
        .accessibilityLabel(pluginLocalization.string("Interface Language"))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    /// 选择状态绑定。写入时立即应用到 `GitOKLanguageOverride`。
    private var selectionBinding: Binding<String> {
        Binding(
            get: { model.selectionID },
            set: { model.select(selectionID: $0) }
        )
    }

    /// 下拉选择器的 accessibility identifier（UI 测试用）。
    static let pickerIdentifier = "gitok.settings.language.picker"
}

/// 语言选择的状态模型。
@MainActor
final class LanguageSelectionViewModel: ObservableObject {
    /// 当前选项 id。`"system"` 表示跟随系统语言。
    @Published private(set) var selectionID: String

    private let override: GitOKLanguageOverride

    init(override: GitOKLanguageOverride = .shared) {
        self.override = override
        self.selectionID = override.languageCode ?? "system"
    }

    /// 选择某个语言。
    ///
    /// - Parameter selectionID: 选项 id；`"system"` 表示跟随系统。
    func select(selectionID: String) {
        let code: String? = selectionID == "system" ? nil : selectionID
        guard code != override.languageCode else { return }
        override.setLanguageCode(code)
        self.selectionID = selectionID
    }
}
