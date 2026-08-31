import Foundation
import SwiftUI

/// 提交时间信息显示组件
/// 显示可点击的提交时间信息，支持hover效果和详细信息弹窗
public struct CommitTimeInfo: View {
    /// 提交对象
    let date: Date

    /// 是否显示时间详情弹窗
    @Binding var showingTimePopup: Bool

    public init(date: Date, showingTimePopup: Binding<Bool>) {
        self.date = date
        self._showingTimePopup = showingTimePopup
    }

    public var body: some View {
        // 提交时间
        if date != Date(timeIntervalSince1970: 0) {
            Button {
                showingTimePopup = true
            } label: {
                Label(fullDateTime, systemImage: "clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .help("点击查看完整时间信息")
            .popover(isPresented: $showingTimePopup, arrowEdge: .bottom) {
                CommitTimePopup(date: date)
                    .frame(width: 350)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
    }

    private var fullDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}
