import Foundation
import SwiftUI

/// 提交信息显示视图组件
/// 包含提交消息、作者信息、时间和 Hash 等详细信息
public struct CommitInfoView: View {
    let message: String
    let bodyText: String
    let author: String
    let date: Date
    let hash: String

    /// 是否已复制到剪贴板
    @State private var isCopied: Bool = false


    /// 是否显示提交时间详情弹窗
    @State private var showingTimePopup = false

    /// 是否显示提交Hash详情弹窗
    @State private var showingHashPopup = false

    public init(message: String, bodyText: String, author: String, date: Date, hash: String) {
        self.message = message
        self.bodyText = bodyText
        self.author = author
        self.date = date
        self.hash = hash
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            /// 提交消息头部显示
            HStack {
                /// Commit 图标
                Image(systemName: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 12))

                /// Commit 消息
                Text(message)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()
            }

            Divider()

            /// Commit body（如果有）
            CommitBodyInfo(bodyText: bodyText)

            /// 提交详细信息区域
            HStack(spacing: 16) {
                /// 作者信息
                CommitInfoUser(author: author)

                /// 提交时间
                CommitTimeInfo(date: date, showingTimePopup: $showingTimePopup)

                /// Hash 信息
                CommitHashInfo(hash: hash, isCopied: $isCopied, showingHashPopup: $showingHashPopup)

                Spacer()
            }
        }
    }
}
