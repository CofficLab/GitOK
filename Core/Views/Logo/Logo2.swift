import SwiftUI

struct Logo2: View {
    var isMonochrome: Bool = false
    var disableAnimation: Bool = false
    @State private var scale: CGFloat = 1.0
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let c1 = isMonochrome ? Color.white : Color.green
            let c2 = isMonochrome ? Color.black : Color.blue
            ZStack {
                Circle()
                    .stroke(c1.opacity(0.85), lineWidth: size * 0.08)
                    .scaleEffect(scale)
                Circle()
                    .stroke(c2.opacity(0.45), lineWidth: size * 0.04)
                    .scaleEffect(scale * 0.82)
                Circle()
                    .fill(c1.opacity(0.08))
                    .frame(width: size * 0.94, height: size * 0.94)
            }
            .frame(width: size, height: size)
            .onAppear {
                if !disableAnimation {
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        scale = 1.06
                    }
                }
            }
        }
    }
}

#Preview("Logo2 Preview") {
    Logo2()
        .frame(width: 120, height: 120)
        .background(Color.black.opacity(0.85))
}
