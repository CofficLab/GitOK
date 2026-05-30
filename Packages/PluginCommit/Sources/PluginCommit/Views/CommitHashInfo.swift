import AppKit
import SwiftUI

/// 提交Hash信息显示组件
/// 显示可点击的提交Hash信息，支持hover效果和详细信息弹窗
public struct CommitHashInfo: View {
    /// 提交对象
    let hash: String

    /// 是否已复制到剪贴板
    @Binding var isCopied: Bool

    /// 是否显示Hash详情弹窗
    @Binding var showingHashPopup: Bool

    public init(
        hash: String,
        isCopied: Binding<Bool>,
        showingHashPopup: Binding<Bool>
    ) {
        self.hash = hash
        self._isCopied = isCopied
        self._showingHashPopup = showingHashPopup
    }

    public var body: some View {
        // Hash 信息
        if !hash.isEmpty {
            iconButton(
                systemImage: "number",
                label: String(hash.prefix(8))
            ) {
                showingHashPopup = true
            }
            .help("点击查看完整 Hash 信息")
            .padding(.trailing, 26)
            .overlay(alignment: .trailing) {
                iconButton(
                    systemImage: isCopied ? "checkmark.circle" : "doc.on.doc",
                    tint: isCopied ? .green : .secondary,
                    isActive: isCopied,
                    compact: true
                ) {
                    copy(hash)
                    withAnimation(.spring()) {
                        isCopied = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.spring()) {
                            isCopied = false
                        }
                    }
                }
                .padding(.trailing, 2)
                .help(isCopied ? "已复制" : "复制完整 Hash")
            }
            .popover(isPresented: $showingHashPopup, arrowEdge: .bottom) {
                CommitHashPopup(hash: hash, isCopied: $isCopied)
                    .frame(width: 450)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
    }

    private func iconButton(
        systemImage: String,
        label: String? = nil,
        tint: Color = .secondary,
        isActive: Bool = false,
        compact: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: compact ? 10 : 11, weight: .semibold))
                if let label {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundStyle(tint)
            .padding(compact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(isActive ? 0.16 : 0.08))
            )
        }
        .buttonStyle(.plain)
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
