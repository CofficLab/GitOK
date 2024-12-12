import SwiftUI

protocol SuperPlugin {
    var label: String { get }
    var icon: String { get }
    var isTab: Bool { get }
    
    func addDBView() -> AnyView
    func addListView() -> AnyView
    func addDetailView() -> AnyView
    func addToolBarLeadingView() -> AnyView
    func addToolBarTrailingView() -> AnyView
    
    func onInit() -> Void
    func onAppear(project: Project?) -> Void
    func onDisappear() -> Void
    func onPlay() -> Void
    func onPlayStateUpdate() -> Void
    func onPlayAssetUpdate() -> Void
}

extension SuperPlugin {
    func addToolBarLeadingView() -> AnyView {
        AnyView(EmptyView())
    }

    func addToolBarTrailingView() -> AnyView {
        AnyView(EmptyView())
    }

    func addDetailView() -> AnyView {
        AnyView(EmptyView())
    }
}
