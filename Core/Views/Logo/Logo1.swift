import SwiftUI

struct Logo1: View {
    var isMonochrome: Bool = false
    var disableAnimation: Bool = false
    @State private var rotation: Double = 0
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let r = size * 0.35
            let base = isMonochrome ? Color.white : Color.blue
            let accent = isMonochrome ? Color.black : Color.purple
            ZStack {
                Circle()
                    .stroke(base.opacity(0.6), lineWidth: size * 0.06)
                    .frame(width: r * 2, height: r * 2)
                Circle()
                    .fill(accent)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .offset(x: r)
                    .rotationEffect(.degrees(rotation))
                Circle()
                    .fill(base.opacity(0.12))
                    .frame(width: size * 0.92, height: size * 0.92)
            }
            .frame(width: size, height: size)
            .onAppear {
                if !disableAnimation {
                    withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
        }
    }
}

#Preview("Logo1 Preview") {
    Logo1()
        .frame(width: 120, height: 120)
        .background(Color.black.opacity(0.85))
}
