import AppKit
import GitOKUI
import SwiftUI

/// 提交Hash详情弹出组件
/// 显示提交的完整Hash信息，包括多种格式和统计信息
public struct CommitHashPopup: View {
    /// 要显示Hash的提交对象
    let hash: String

    /// 复制状态绑定（从父视图传递）
    @Binding var isCopied: Bool

    public init(hash: String, isCopied: Binding<Bool>) {
        self.hash = hash
        self._isCopied = isCopied
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("提交 Hash 详情")
                .font(.headline)
                .foregroundColor(.primary)

            Divider()

            // Hash 信息列表
            VStack(spacing: 12) {
                // 完整 Hash
                hashInfoRow(
                    title: "完整 Hash",
                    value: hash,
                    icon: "number.circle.fill",
                    selectable: true,
                    showCopyButton: true
                )

                // 短 Hash (8位)
                hashInfoRow(
                    title: "短 Hash (8位)",
                    value: String(hash.prefix(8)),
                    icon: "number.circle",
                    selectable: true,
                    showCopyButton: true
                )

                // Hash 长度
                hashInfoRow(
                    title: "Hash 长度",
                    value: "\(hash.count) 字符",
                    icon: "ruler",
                    selectable: false,
                    showCopyButton: false
                )

                // Hash 前缀检查
                if hash.hasPrefix("0") {
                    hashInfoRow(
                        title: "前缀特征",
                        value: "以 0 开头",
                        icon: "exclamationmark.triangle",
                        selectable: false,
                        showCopyButton: false
                    )
                }
            }
        }
        .padding(20)
    }

    /// Hash信息行组件
    /// - Parameters:
    ///   - title: 信息标题
    ///   - value: 信息值
    ///   - icon: 系统图标名称
    ///   - selectable: 是否可选择文本
    ///   - showCopyButton: 是否显示复制按钮
    /// - Returns: 配置好的视图
    private func hashInfoRow(title: String, value: String, icon: String, selectable: Bool, showCopyButton: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 16))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if selectable {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                } else {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            if showCopyButton {
                AppIconButton(
                    systemImage: isCopied ? "checkmark.circle.fill" : "doc.on.doc.fill",
                    tint: isCopied ? .green : .secondary,
                    size: .regular,
                    isActive: isCopied
                ) {
                    copy(value)
                    withAnimation(.spring()) {
                        isCopied = true
                    }

                    // 1.5秒后重置状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.spring()) {
                            isCopied = false
                        }
                    }
                }
                .help(isCopied ? "已复制" : "复制到剪贴板")
            }
        }
        .padding(.vertical, 8)
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
