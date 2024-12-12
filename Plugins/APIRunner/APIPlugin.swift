import SwiftUI

class APIPlugin: SuperPlugin {
    let emoji = "🌐"
    var label: String = "API Runner"
    var icon: String = "network"
    var isTab: Bool = true
    
    let apiProvider = APIProvider()

    func addDBView() -> AnyView {
        AnyView(EmptyView())
    }

    func addListView() -> AnyView {
        AnyView(APIList().environmentObject(apiProvider))
    }

    func addDetailView() -> AnyView {
        AnyView(APIDetail().environmentObject(apiProvider))
    }
    
    func addToolBarTrailingView() -> AnyView {
        AnyView(EmptyView())
    }

    func onInit() {
        // 初始化操作
    }

    func onAppear() {
        // 出现时的操作
    }

    func onDisappear() {
        // 消失时的操作
    }

    func onPlay() {
        // 播放时的操作
    }

    func onPlayStateUpdate() {
        // 播放状态更新时的操作
    }

    func onPlayAssetUpdate() {
        // 播放资源更新时的操作
    }
}
