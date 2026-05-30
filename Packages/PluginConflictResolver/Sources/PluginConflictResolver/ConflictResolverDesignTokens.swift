import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
    }

    enum Typography {
        static let title3 = Font.title3.weight(.semibold)
        static let bodyEmphasized = Font.body.weight(.semibold)
        static let caption1 = Font.caption
    }

    enum Material {
        static let glass = SwiftUI.Color.primary.opacity(0.06)
    }

    enum Color {
        enum semantic {
            static let textPrimary = SwiftUI.Color.primary
            static let textSecondary = SwiftUI.Color.secondary
            static let textTertiary = SwiftUI.Color.secondary.opacity(0.8)
            static let warning = SwiftUI.Color.orange
            static let success = SwiftUI.Color.green
            static let info = SwiftUI.Color.blue
            static let error = SwiftUI.Color.red
        }
    }
}
