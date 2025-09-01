
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
    @Published private(set) var banner: BannerData = .empty
    
    /// 当前选中的设备
    @Published private(set) var selectedDevice: Device = .iPhoneBig

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
    
    /**
        设置当前选中的设备
        
        ## 参数
        - `device`: 要设置为当前选中的设备
    */
    func setSelectedDevice(_ device: Device) {
        if !Thread.isMainThread {
            assertionFailure("setSelectedDevice called from background thread")
        }
        
        self.selectedDevice = device
    }
    
    /**
        更新当前Banner的特定属性
        
        ## 参数
        - `update`: 用于更新Banner的闭包
    */
    func updateBanner(_ update: (inout BannerData) -> Void) {
        if !Thread.isMainThread {
            assertionFailure("updateBanner called from background thread")
        }
        
        var updatedBanner = self.banner
        update(&updatedBanner)
        self.banner = updatedBanner
    }
    
    /**
        更新当前Banner的特定属性（支持抛出错误）
        
        ## 参数
        - `update`: 用于更新Banner的闭包，可以抛出错误
        - `throws`: 如果更新过程中发生错误
    */
    func updateBanner(_ update: (inout BannerData) throws -> Void) throws {
        if !Thread.isMainThread {
            assertionFailure("updateBanner called from background thread")
        }
        
        var updatedBanner = self.banner
        try update(&updatedBanner)
        self.banner = updatedBanner
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 700)
    .frame(height: 800)
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

