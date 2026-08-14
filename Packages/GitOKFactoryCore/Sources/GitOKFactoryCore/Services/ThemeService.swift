import GitOKAppCore
import GitOKCoreKit
import GitOKUI
import SwiftUI

@MainActor
public final class ThemeService: GitOKThemeServicing {
    public let themeVM: AppThemeVM

    public init(themeVM: AppThemeVM) {
        self.themeVM = themeVM
    }

    public var currentThemeId: String { themeVM.currentThemeId }

    public func selectTheme(_ themeId: String) {
        themeVM.selectTheme(themeId)
    }
}
