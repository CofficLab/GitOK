import GitOKFoundationKit
import MagicAlert
import SwiftUI

extension MagicContainer {
    /// 截图功能实现 (使用snapshot方法)
    func captureView() {
        #if os(macOS)
            let widthInt = Int(containerWidth)
            let heightInt = Int(containerHeight)
            let title = "MagicContainer_\(Date().compactDateTime)_\(widthInt)x\(heightInt)"
            do {
                try content.frame(width: containerWidth, height: containerHeight).snapshot(title: title, scale: 1)
                alert_success("截图已保存到下载文件夹")
            } catch {
                alert_error(error)
            }
        #endif
    }
}


