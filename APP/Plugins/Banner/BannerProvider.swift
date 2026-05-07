import AVKit
import Combine
import Foundation
import MagicKit
import MagicDevice
import MediaPlayer
import OSLog
import SwiftUI

/**
     Banner状态管理器
 **/
@MainActor
class BannerProvider: NSObject, ObservableObject, SuperLog {
    static let shared = BannerProvider()

    

    /// 当前选中的Banner
    @Published private(set) var banner: BannerFile = .empty

    /// 当前选中的设备
    @Published private(set) var selectedDevice: MagicDevice = .iPhoneBig

    /// 当前选中的模板
    @Published private(set) var selectedTemplate: any BannerTemplateProtocol = ClassicBannerTemplate()

    var emoji = "🐘"

    // MARK: - Banner状态管理方法

    /**
         设置当前选中的Banner

         ## 参数
         - `b`: 要设置为当前选中的Banner数据
     */
    func setBanner(_ b: BannerFile) {
        if !Thread.isMainThread {
            assertionFailure("setBanner called from background thread")
        }
        
        if self.banner.id == b.id {
            return
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
    func setSelectedDevice(_ device: MagicDevice) {
        if !Thread.isMainThread {
            assertionFailure("setSelectedDevice called from background thread")
        }

        self.selectedDevice = device
    }

    /**
         更新当前Banner的特定属性（支持抛出错误）

         ## 参数
         - `update`: 用于更新Banner的闭包，可以抛出错误
         - `throws`: 如果更新过程中发生错误
     */
    func updateBanner(_ update: (inout BannerFile) throws -> Void) throws {
        if !Thread.isMainThread {
            assertionFailure("updateBanner called from background thread")
        }

        var updatedBanner = self.banner
        try update(&updatedBanner)
        self.banner = updatedBanner

        try BannerRepo.shared.saveBanner(banner)
    }

    /**
         设置当前选中的模板

         ## 参数
         - `template`: 要设置为当前选中的模板
     */
    func setSelectedTemplate(_ template: any BannerTemplateProtocol) {
        if !Thread.isMainThread {
            assertionFailure("setSelectedTemplate called from background thread")
        }

        self.selectedTemplate = template
        
        // 保存选择的模板ID
        try? updateBanner { banner in
            banner.lastSelectedTemplateId = template.id
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .setInitialTab("Banner")
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
