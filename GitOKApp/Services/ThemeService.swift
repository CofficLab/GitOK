import GitOKAppCore
import GitOKCoreKit
import GitOKUI
import SwiftUI

@MainActor
final class ThemeService: GitOKThemeServicing {
    let themeVM: AppThemeVM

    init(themeVM: AppThemeVM) {
        self.themeVM = themeVM
    }

    var currentThemeId: String { themeVM.currentThemeId }

    func selectTheme(_ themeId: String) {
        themeVM.selectTheme(themeId)
    }
}
