import SwiftUI

protocol SuperPlugin {
    var label: String { get }
    
    var isTab: Bool { get }

    func addDBView() -> AnyView
    func addListView() -> AnyView
    func addDetailView() -> AnyView
    
    func onInit() -> Void
    func onAppear() -> Void
    func onDisappear() -> Void
    func onPlay() -> Void
    func onPlayStateUpdate() -> Void
    func onPlayAssetUpdate() -> Void
}
