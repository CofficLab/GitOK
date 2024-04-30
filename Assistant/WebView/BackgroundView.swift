import SwiftUI

struct BackgroundView: View {
    var colorScheme: ColorScheme = .light
    
    static var all: [String: AnyView] = [
        "1": AnyView(ZStack { BackgroundView.type1 }),
        "1_opaque": AnyView(ZStack { BackgroundView.type1_opaque }),
        "2": AnyView(ZStack { BackgroundView.type2 }),
        "2_opaque": AnyView(ZStack { BackgroundView.type2_opaque }),
        "2A": AnyView(ZStack { BackgroundView.type2A }),
        "2A_opaque": AnyView(ZStack { BackgroundView.type2A_opaque }),
        "2B": AnyView(ZStack { BackgroundView.type2B }),
        "3": AnyView(ZStack { BackgroundView.type3 }),
        "4": AnyView(ZStack { BackgroundView.type4 }),
        "5": AnyView(ZStack { BackgroundView.type5 }),
        "6": AnyView(ZStack { BackgroundView.type6 }),
        "sky": AnyView(ZStack { BackgroundView.sky }),
        "ocean": AnyView(ZStack { BackgroundView.ocean }),
        "forest": AnyView(ZStack { BackgroundView.forest })
    ]
    
    var body: some View {
        BackgroundView.type1
    }
    
    static var type1: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.yellow.opacity(0.4), 
                        Color.blue
                    ]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Color.green.opacity(0.2).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var type1_opaque: some View {
        ZStack {
            Color.white.opacity(1)
            type1
        }.ignoresSafeArea()
    }
    
    static var type2: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [Color.green.opacity(0.4), Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }.ignoresSafeArea()
    }
    
    static var type2_opaque: some View {
        ZStack {
            Color.white.opacity(1)
            type2
        }.ignoresSafeArea()
    }
    
    static var type2A: some View {
        ZStack {
            type2
            Color.green.opacity(0.2).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var type2A_opaque: some View {
        ZStack {
            Color.white
            type2
            Color.green.opacity(0.2).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var type2B: some View {
        ZStack {
            type2
            Color.white.opacity(0.2).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var type3: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.green.opacity(0.3),
                        Color.blue.opacity(0.3)
                    ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Color.black.opacity(0.2).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var type4: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.green.opacity(0.3),
                        Color.blue.opacity(0.3)
                    ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Color.black.opacity(0.6).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var type5: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.blue.opacity(0.9)
                    ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }.ignoresSafeArea()
    }
    
    static var type6: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.yellow.opacity(0.9),
                    ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }.ignoresSafeArea()
    }
    
    static var preview: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.green.opacity(0.3),
                        Color.blue.opacity(0.3)
                    ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Text("Preview 专用背景").opacity(0.4).font(.title)

            Color.black.opacity(0.4).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var sky: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.blue.opacity(0.7),
                        Color.blue.opacity(0.3)
                    ]),
                startPoint: .top,
                endPoint: .bottom
            )

            Color.black.opacity(0.2).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var ocean: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.green.opacity(0.3)
                    ]),
                startPoint: .top,
                endPoint: .bottom
            )

            Color.black.opacity(0.2).blur(radius: 2)
        }.ignoresSafeArea()
    }
    
    static var forest: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.green.opacity(0.3),
                        Color.green.opacity(0.1)
                    ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Color.black.opacity(0.2).blur(radius: 2)
        }.ignoresSafeArea()
    }
}

#Preview {
    VStack {
        ForEach(BackgroundView.all.sorted(by: { $0.key < $1.key }), id: \.key) { x, value in
            ZStack {
                value
                Text("\(x)")
            }
        }
    }
    .frame(width: 200)
    .frame(height: 800)
}
