import SwiftUI

/// 标题对齐方式枚举
public enum AppSettingSectionTitleAlignment {
    case leading
    case center
    case trailing
}

/// 分组设置容器
public struct AppSettingSection<Content: View>: View {
    let title: String?
    let titleAlignment: AppSettingSectionTitleAlignment
    let content: Content

    public init(
        title: String? = nil,
        titleAlignment: AppSettingSectionTitleAlignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleAlignment = titleAlignment
        self.content = content()
    }

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                if let title {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(
                            maxWidth: .infinity,
                            alignment: titleAlignment == .leading ? .leading : titleAlignment == .center ? .center : .trailing
                        )
                        .padding(.leading, titleAlignment == .leading ? 4 : 0)
                        .padding(.trailing, titleAlignment == .trailing ? 4 : 0)
                }

                content
                    .padding(.leading, 4)
            }
            .padding(.vertical, 12)
        }
    }
}
