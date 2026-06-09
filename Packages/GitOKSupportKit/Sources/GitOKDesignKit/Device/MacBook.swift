import GitOKFoundationKit
import SwiftUI

public struct MacBookDevice: SuperScreen {
    public var screenWidth: CGFloat {
        2550
    }

    public var screenHeight: CGFloat {
        1650
    }

    public var deviceImageName: String {
        "MacBook Air 13\" - 4th Gen - Midnight"
    }

    public var landscapeImageName: String? {
        nil
    }

    public var screenOffsetX: CGFloat {
        0
    }

    public var screenOffsetY: CGFloat {
        0
    }
}

public struct MacBookScreen<Content>: View where Content: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScreenBase(device: MacBookDevice(), horizon: false) {
            content
        }
    }
}

// MARK: - Preview

