import SwiftUI

struct BackgroundGroup {
    static var all: [String: AnyView] = [
        "blue2yellow_tl2br": AnyView(ZStack { BackgroundGroup.blue2yellow_tl2br }),
        "blue2green": AnyView(ZStack { BackgroundGroup.blue2green }),
        "blue2cyan": AnyView(ZStack { BackgroundGroup.blue2cyan }),
        "blue2clear_tl2br": AnyView(ZStack { BackgroundGroup.blue2clear_tl2br }),
        "blue2indigo_tl2br": AnyView(ZStack { BackgroundGroup.blue2indigo_tl2br }),
        "yellow2blue_tl2br": AnyView(ZStack { BackgroundGroup.yellow2blue_tl2br }),
        "green2blue_tl2br": AnyView(ZStack { BackgroundGroup.green2blue_tl2br }),
        "green2cyan_tl2br": AnyView(ZStack { BackgroundGroup.green2cyan_tl2br }),
    ]
    
    // MARK: yellow2blue-tl2br
    
    static var yellow2blue_tl2br: some View {
        from2(.yellow, .blue, .topLeading, .bottomTrailing)
    }
    
    // MARK: blue2yellow-tl2br
    
    static var blue2yellow_tl2br: some View {
        from2(.blue, .yellow, .topLeading, .bottomTrailing)
    }
    
    // MARK: blue2clear-tl2br
    
    static var blue2clear_tl2br: some View {
        from2(.blue, .clear, .topLeading, .bottomTrailing)
    }
    
    // MARK: blue2indigo-tl2br
    
    static var blue2indigo_tl2br: some View {
        from2(.blue, .indigo, .topLeading, .bottomTrailing)
    }
    
    // MARK: blue2cyan
    
    static var blue2cyan: some View {
        from2(.blue, .cyan, .top, .bottom)
    }
    
    // MARK: green2blue-tl2br
    
    static var green2blue_tl2br: some View {
        from2(.green, .blue, .topLeading, .bottomTrailing)
    }
    
    // MARK: green2cyan-tl2br
    
    static var green2cyan_tl2br: some View {
        from2(.green, .cyan, .topLeading, .bottomTrailing)
    }
    
    // MARK: blue2green
    
    static var blue2green: some View {
        from2(.blue, .green, .top, .bottom)
    }
    
    private static func from2(_ from: Color, _ to: Color, _ start: UnitPoint, _ end: UnitPoint)->some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        from,
                        to
                    ]),
                startPoint: start,
                endPoint: end
            )
        }.ignoresSafeArea()
    }
}

#Preview {
    HStack {
        ForEach(1...10, id: \.self) { i in
            let opacity = Double(i)/10.0
            VStack {
                ForEach(BackgroundGroup.all.sorted(by: { $0.key < $1.key }), id: \.key) { x, value in
                    ZStack {
                        value.opacity(opacity)
                        VStack {
                            Text("\(x)").padding(.vertical)
                            Text("\(String(format: "%.1f", opacity))")
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    .frame(width: 1200)
    .frame(height: 800)
}
