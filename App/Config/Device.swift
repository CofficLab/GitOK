import Foundation
import SwiftUI

enum Device: String, Equatable {
    case iMac
    case MacBook
    case iPhoneBig
    case iPhoneSmall
    case iPad

    var isMac: Bool {
        self.type == .Mac
    }

    var isiPhone: Bool {
        self.type == .iPhone
    }

    var isiPad: Bool {
        self.type == .iPad
    }

    var type: DeviceType {
        switch self {
        case .iMac:
            return .Mac
        case .MacBook:
            return .Mac
        case .iPad:
            return .iPad
        case .iPhoneBig:
            return .iPhone
        case .iPhoneSmall:
            return .iPhone
        }
    }

    var description: String {
        switch self {
        case .iMac:
            return "iMac"
        case .MacBook:
            return "MacBook"
        case .iPad:
            return "iPad - 13英寸显示屏"
        case .iPhoneBig:
            return "iPhone - 6.9英寸显示屏"
        case .iPhoneSmall:
            return "iPhone - 6.5英寸显示屏"
        }
    }

    var systemImageName: String {
        switch self {
        case .iMac:
            return "desktopcomputer"
        case .MacBook:
            return "laptopcomputer"
        case .iPad:
            return "ipad"
        case .iPhoneBig:
            return "iphone"
        case .iPhoneSmall:
            return "iphone"
        }
    }

    var width: CGFloat {
        switch self {
        case .iMac:
            2880
        case .MacBook:
            2880
        case .iPhoneBig:
            1290
        case .iPhoneSmall:
            1242
        case .iPad:
            2048
        }
    }

    var height: CGFloat {
        switch self {
        case .iMac:
            1800
        case .MacBook:
            1800
        case .iPhoneBig:
            2796
        case .iPhoneSmall:
            2208
        case .iPad:
            2732
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .setInitialTab(IconPlugin.label)
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .setInitialTab(BannerPlugin.label)
        .hideProjectActions()
        .hideTabPicker()
        .hideSidebar()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
