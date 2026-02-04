import SwiftUI

struct Logo5: View {
    var isMonochrome: Bool = false
    var disableAnimation: Bool = false
    @State private var pulse: CGFloat = 0.95
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let base = isMonochrome ? Color.white : Color.orange
            ZStack {
                Circle()
                    .fill(base.opacity(0.12))
                    .frame(width: size * 0.94, height: size * 0.94)
                Circle()
                    .fill(base)
                    .frame(width: size * 0.56, height: size * 0.56)
                    .scaleEffect(pulse)
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.36)
                    .foregroundColor(isMonochrome ? .black : .white)
            }
            .frame(width: size, height: size)
            .onAppear {
                if !disableAnimation {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        pulse = 1.05
                    }
                }
            }
        }
    }
}

#Preview("Logo5 Preview") {
    Logo5()
        .frame(width: 120, height: 120)
        .background(Color.black.opacity(0.85))
}
