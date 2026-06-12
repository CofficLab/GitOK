import GitOKFoundationKit
import SwiftUI

public struct iPhoneDevice: SuperScreen {
    public var horizon: Bool = false

    public init(horizon: Bool = false) {
        self.horizon = horizon
    }

    public var screenWidth: CGFloat {
        horizon ? 2600 : 1165
    }

    public var screenHeight: CGFloat {
        horizon ? 1200 : 2528
    }

    public var deviceImageName: String {
        "iPhone 14 - Midnight - Portrait"
    }

    public var landscapeImageName: String? {
        "iPhone 14 - Midnight - Landscape"
    }

    public var screenOffsetX: CGFloat {
        0
    }

    public var screenOffsetY: CGFloat {
        0
    }
}

public struct iPhoneScreen<Content>: View where Content: View {
    private let content: Content
    public var horizon = false

    public init(horizon: Bool = false, @ViewBuilder content: () -> Content) {
        self.horizon = horizon
        self.content = content()
    }

    public var body: some View {
        ScreenBase(device: iPhoneDevice(horizon: horizon), horizon: horizon) {
            content
        }
    }
}

// MARK: - Preview


