import SwiftUI

struct Logo4: View {
    var isMonochrome: Bool = false
    var disableAnimation: Bool = false
    @State private var phase: CGFloat = 0
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let color = isMonochrome ? Color.white : Color.indigo
            VStack(spacing: size * 0.08) {
                Capsule()
                    .fill(color.opacity(0.9))
                    .frame(width: size * 0.82, height: size * 0.14)
                    .offset(y: phase)
                Capsule()
                    .fill(color.opacity(0.6))
                    .frame(width: size * 0.72, height: size * 0.12)
                    .offset(y: -phase)
                Capsule()
                    .fill(color.opacity(0.4))
                    .frame(width: size * 0.62, height: size * 0.10)
            }
            .frame(width: size, height: size)
            .onAppear {
                if !disableAnimation {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        phase = size * 0.04
                    }
                }
            }
        }
    }
}

#Preview("Logo4 Preview") {
    Logo4()
        .frame(width: 120, height: 120)
        .background(Color.black.opacity(0.85))
}
