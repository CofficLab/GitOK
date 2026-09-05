import LumiUI
import ProviderProjects
import SwiftUI

/// 根视图级冲突弹层宿主。
///
/// 冲突产生时由 ViewModel 自动打开；状态栏入口也通过同一个 ViewModel
/// 打开。根视图 Overlay 保证弹层不依赖某个局部控件或当前工作场景。
@MainActor
struct ConflictResolverOverlayHost: View {
    let content: AnyView
    let projects: any ProjectProviding
    @ObservedObject var viewModel: GitConflictResolverViewModel

    var body: some View {
        ZStack {
            content

            if viewModel.isPresented {
                Color.black
                    .opacity(0.18)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ConflictResolverList(
                    projects: projects,
                    viewModel: viewModel,
                    onDismiss: viewModel.dismiss
                )
                .frame(width: 680, height: 560)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.22), radius: 24, y: 8)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.isPresented)
    }

    @LumiTheme private var theme: LumiUITheme
}
