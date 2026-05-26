import SwiftUI

public extension View {
    /// 神秘背景效果（基于当前或指定 chrome 主题）
    func gitOKUIMystiqueBackground(theme: (any GitOKAppChromeTheme)? = nil) -> some View {
        let activeTheme = theme ?? ChromeThemes.current
        return background(
            LinearGradient(
                colors: [
                    activeTheme.atmosphereColors().deep,
                    activeTheme.atmosphereColors().medium,
                    activeTheme.atmosphereColors().light,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    /// 神秘光晕效果
    func gitOKUIMystiqueGlow(intensity: Double = 0.15) -> some View {
        let colors = ChromeThemes.current.glowColors()
        return gitOKUIGlowEffect(
            color: colors.medium,
            radius: ChromeThemes.Effects.glowRadius,
            intensity: intensity
        )
    }

    /// 神秘边框
    func gitOKUIMystiqueBorder(cornerRadius: CGFloat = 16) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(ChromeThemes.Gradients.mysticBorder, lineWidth: 1.5)
        )
    }
}
