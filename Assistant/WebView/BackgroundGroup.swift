import SwiftUI

struct BackgroundGroup {
    static var all: [String: AnyView] = [
        "blue2yellow": AnyView(ZStack { BackgroundGroup.blue2yellow }),
        "blue2green": AnyView(ZStack { BackgroundGroup.blue2green }),
        "blue2cyan": AnyView(ZStack { BackgroundGroup.blue2cyan }),
        "yellow2blue": AnyView(ZStack { BackgroundGroup.yellow2blue }),
        "green2blue": AnyView(ZStack { BackgroundGroup.green2blue }),
    ]
    
    // MARK: yellow2blue
    
    static var yellow2blue: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.yellow,
                        Color.blue
                    ]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }.ignoresSafeArea()
    }
    
    // MARK: blue2yellow
    
    static var blue2yellow: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.blue,
                        Color.yellow,
                    ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }.ignoresSafeArea()
    }
    
    // MARK: blue2cyan
    
    static var blue2cyan: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.blue,
                        Color.cyan,
                    ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }.ignoresSafeArea()
    }
    
    // MARK: green2blue
    
    static var green2blue: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.green,
                        Color.blue
                    ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }.ignoresSafeArea()
    }
    
    // MARK: blue2green
    
    static var blue2green: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.blue,
                        Color.green
                    ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }.ignoresSafeArea()
    }
}

#Preview {
    HStack {
        ForEach(1...10, id: \.self) { i in
            let opacity = Double(i)/10.0
            VStack {
                Text("\(String(format: "%.1f", opacity))")
                ForEach(BackgroundGroup.all.sorted(by: { $0.key < $1.key }), id: \.key) { x, value in
                    ZStack {
                        value.opacity(opacity)
                        VStack {
                            Text("\(x)").padding(.vertical)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    .frame(width: 1000)
    .frame(height: 800)
}
