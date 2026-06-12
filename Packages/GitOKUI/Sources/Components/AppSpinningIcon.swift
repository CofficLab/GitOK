import SwiftUI

public struct AppSpinningIcon: View {
    @GitOKMotionPreferenceReader private var motionPreference
    @State private var isRotating = false

    private let systemImage: String
    private let size: CGFloat
    private let weight: Font.Weight

    public init(
        systemImage: String = "arrow.triangle.2.circlepath",
        size: CGFloat = 14,
        weight: Font.Weight = .semibold
    ) {
        self.systemImage = systemImage
        self.size = size
        self.weight = weight
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size, weight: weight))
            .frame(width: size + 2, height: size + 2)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .onAppear {
                guard motionPreference.allowsMotion else { return }
                withAnimation(.linear(duration: 0.85).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
            }
    }
}

#Preview {
    AppSpinningIcon()
        .padding()
}
