import LumiUI
import ProviderRootView
import SwiftUI

/// Toolbar button that toggles the left sidebar visibility.
///
/// Clicking the button toggles the sidebar between hidden and visible states.
/// The button always shows a sidebar icon; the actual sidebar visibility is
/// managed by `RootViewProviding`.
struct SidebarToggleButtonView: View {
    let rootView: any RootViewProviding

    var body: some View {
        AppIconButton(systemImage: "sidebar.leading", size: .regular) {
            rootView.setSidebarViewHidden(!rootView.isSidebarViewHidden)
        }
        .help("Toggle Sidebar")
    }
}
