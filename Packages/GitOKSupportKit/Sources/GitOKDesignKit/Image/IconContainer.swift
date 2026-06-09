import GitOKFoundationKit
import SwiftUI

public struct IconContainer<Content: View>: View {
    private let content: Content
    private let fixedSize: CGFloat?
    private let shape: IconShape

    public init(
        size: CGFloat? = nil,
        shape: IconShape = .rectangle,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.fixedSize = size
        self.shape = shape
    }

    public var body: some View {
        let contentView: some View = if let size = fixedSize {
            AnyView(content.frame(width: size, height: size))
        } else {
            AnyView(content)
        }

        switch shape {
        case .rectangle:
            contentView
        case .circle:
            contentView.clipShape(Circle())
        case let .roundedRectangle(radius):
            contentView.clipShape(RoundedRectangle(cornerRadius: radius))
        }
    }
}

// 更新预览以展示新的形状选项
