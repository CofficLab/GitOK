
import AVKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI
import MagicCore

/**
    Banner状态管理器
**/
@MainActor
class BannerProvider: NSObject, ObservableObject, SuperLog {
    static let shared = BannerProvider()
    
    private override init() {}
    
    /// 当前选中的Banner
    @Published var banner: BannerData = .empty

    var emoji = "🐘"
    
    // MARK: - Banner状态管理方法

    /**
        设置当前选中的Banner
        
        ## 参数
        - `b`: 要设置为当前选中的Banner数据
    */
    func setBanner(_ b: BannerData) {
        if !Thread.isMainThread {
            assertionFailure("setBanner called from background thread")
        }

        self.banner = b
    }
    
    /**
        清除当前选中的Banner
        将当前Banner重置为空状态
    */
    func clearBanner() {
        if !Thread.isMainThread {
            assertionFailure("clearBanner called from background thread")
        }
        
        self.banner = .empty
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

