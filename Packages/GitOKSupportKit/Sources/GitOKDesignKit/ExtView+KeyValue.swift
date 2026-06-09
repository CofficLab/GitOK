import GitOKFoundationKit
import SwiftUI

extension Text {
    /// 为文本添加对应的值，创建键值对行
    /// - Parameter value: 对应的值
    /// - Returns: 键值对行视图
    public func withMagicValue(_ value: String) -> MagicKeyValueRow {
        MagicKeyValueRow(keyText: self, value: value, icon: nil)
    }
}

// MARK: - Preview

