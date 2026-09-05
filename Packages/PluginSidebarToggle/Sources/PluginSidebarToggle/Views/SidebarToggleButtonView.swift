import LumiUI
import ProviderRootView
import SwiftUI

/// Toolbar button that toggles the left sidebar visibility.
///
/// Clicking the button toggles the sidebar between hidden and visible states.
/// The icon reflects the current state — `sidebar.leading` while hidden,
/// `sidebar.squares.leading` while visible — with a symbol-replace animation.
/// The sidebar itself slides in/out along the leading edge (see
/// `DefaultRootHostView`); both animations follow the reduce-motion preference.
struct SidebarToggleButtonView: View {
    let rootView: any RootViewProviding
    @State private var isSidebarHidden = false
    @LumiMotionPreferenceReader private var motionPreference

    var body: some View {
        AppIconButton(
            systemImage: isSidebarHidden ? "sidebar.leading" : "sidebar.squares.leading",
            size: .regular,
            isActive: !isSidebarHidden
        ) {
            LumiMotion.animate(
                LumiMotion.enabled(LumiMotion.disclosure, preference: motionPreference)
            ) {
                rootView.setSidebarViewHidden(!rootView.isSidebarViewHidden)
            }
        }
        .help("Toggle Sidebar")
        .contentTransition(.symbolEffect(.replace))
        .onAppear {
            isSidebarHidden = rootView.isSidebarViewHidden
        }
        .onReceive(rootView.objectWillChange) { _ in
            isSidebarHidden = rootView.isSidebarViewHidden
        }
    }
}
