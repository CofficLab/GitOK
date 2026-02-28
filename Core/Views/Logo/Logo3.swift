import SwiftUI

struct Logo3: View {
    var isMonochrome: Bool = false
    var disableAnimation: Bool = false
    @State private var glow = false
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let spacing = size * 0.14
            let dot = size * 0.18
            let base = isMonochrome ? Color.white : Color.cyan
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    ForEach(0..<3, id: \.self) { j in
                        Circle()
                            .fill(base.opacity((i == 1 && j == 1) ? (glow ? 1.0 : 0.75) : 0.55))
                            .frame(width: dot, height: dot)
                            .offset(x: CGFloat(j - 1) * spacing, y: CGFloat(i - 1) * spacing)
                    }
                }
            }
            .frame(width: size, height: size)
            .onAppear {
                if !disableAnimation {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glow = true
                    }
                }
            }
        }
    }
}

#Preview("Logo3 Preview") {
    Logo3()
        .frame(width: 120, height: 120)
        .background(Color.black.opacity(0.85))
}
