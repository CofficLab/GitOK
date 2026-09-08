import LumiUI
import ProviderProjects
import ProviderGit
import SwiftUI

/// 根视图级冲突弹层宿主。
///
/// 冲突产生时由 ViewModel 自动打开；状态栏入口也通过同一个 ViewModel
/// 打开。根视图 Overlay 保证弹层不依赖某个局部控件或当前工作场景。
@MainActor
struct ConflictResolverOverlayHost: View {
    let content: AnyView
    let projects: any ProjectProviding
    let git: any GitProviding
    @ObservedObject var viewModel: GitConflictResolverViewModel
    @LumiTheme private var theme

    var body: some View {
        ZStack {
            content

            if viewModel.isPresented {
                Color.black
                    // Keep the workspace readable while still establishing modal focus.
                    .opacity(0.12)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ConflictResolverList(
                    projects: projects,
                    git: git,
                    viewModel: viewModel,
                    onDismiss: viewModel.dismiss
                )
                .frame(width: 680, height: 560)
                // A modal needs a stable surface. Using regularMaterial here made
                // the dialog inherit the dimmed workspace and appear gray.
                .appSurface(
                    style: .panel,
                    cornerRadius: 12,
                    borderColor: theme.textTertiary.opacity(0.12)
                )
                .appClipRounded(12)
                .shadow(
                    color: Color.black.opacity(0.14),
                    radius: 20,
                    y: 8
                )
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.isPresented)
    }
}
