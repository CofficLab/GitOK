import LumiUI
import SwiftUI

/// 项目侧边栏底部的展示方式切换栏。
///
/// 出现在侧边栏底部（列表之下），用一组 tab 让用户在项目很多时快速切换
/// 列表的排列规则：手动顺序 / 最近更新 / 按名称。
///
/// 视觉上与侧边栏保持一致：紧凑的 tab 按钮、顶部一条分隔线把列表与
/// 切换栏分开。展示方式较多时 tab 横向滚动，不换行、不挤压列表。
struct ProjectSortBarView: View {
    /// 当前选中的展示方式。
    @Binding var mode: ProjectSortMode

    /// 项目总数；为空时不展示切换栏（没有项目时切换排序没有意义）。
    let projectCount: Int

    @LumiTheme private var theme

    /// 项目数低于该阈值时隐藏切换栏——项目很少时列表本身就好读，
    /// 多余的控件只会增加噪音。
    static let visibilityThreshold = 5

    /// 当前排序方式是否需要读取仓库提交时间（读取期间展示加载指示）。
    var isLoadingActivity: Bool = false

    var body: some View {
        if shouldShow {
            VStack(spacing: 0) {
                AppDivider()
                bar
            }
        }
    }

    /// 排序栏是否可见。
    var shouldShow: Bool {
        projectCount >= Self.visibilityThreshold
    }

    private var bar: some View {
        HStack(spacing: 6) {
            AppTabBar(
                tabs: ProjectSortMode.allCases.map {
                    AppTabBar.Tab(
                        title: pluginLocalization.string($0.titleKey),
                        icon: $0.systemImage,
                        id: $0.id
                    )
                },
                selectedTab: Binding(
                    get: { mode.id },
                    set: { newValue in
                        guard let selected = ProjectSortMode(rawValue: newValue) else { return }
                        mode = selected
                    }
                ),
                showText: false
            )

            Spacer(minLength: 0)

            if isLoadingActivity {
                ProgressView()
                    .controlSize(.mini)
                    .help(pluginLocalization.string("Loading Activity"))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(theme.surface)
    }
}
