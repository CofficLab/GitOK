import SwiftUI

struct BackgroundGroup {
    static var all: [String: AnyView] = [
        "amber2orange_t2b": AnyView(ZStack { BackgroundGroup.amber2orange_t2b }),
        "aquamarine2teal_l2r": AnyView(ZStack { BackgroundGroup.aquamarine2teal_l2r }),
        "beige2brown_tl2br": AnyView(ZStack { BackgroundGroup.beige2brown_tl2br }),
        "black2white_tl2br": AnyView(ZStack { BackgroundGroup.black2white_tl2br }),
        "blue2clear_tl2br": AnyView(ZStack { BackgroundGroup.blue2clear_tl2br }),
        "blue2cyan": AnyView(ZStack { BackgroundGroup.blue2cyan }),
        "blue2green": AnyView(ZStack { BackgroundGroup.blue2green }),
        "blue2indigo_tl2br": AnyView(ZStack { BackgroundGroup.blue2indigo_tl2br }),
        "blue2purple_l2r": AnyView(ZStack { BackgroundGroup.blue2purple_l2r }),
        "blue2white_center": AnyView(ZStack { BackgroundGroup.blue2white_center }),
        "blue2yellow_tl2br": AnyView(ZStack { BackgroundGroup.blue2yellow_tl2br }),
        "brown2orange_l2r": AnyView(ZStack { BackgroundGroup.brown2orange_l2r }),
        "burgundy2pink_bl2tr": AnyView(ZStack { BackgroundGroup.burgundy2pink_bl2tr }),
        "charcoal2silver_r2l": AnyView(ZStack { BackgroundGroup.charcoal2silver_r2l }),
        "coral2peach_t2b": AnyView(ZStack { BackgroundGroup.coral2peach_t2b }),
        "crimson2rose_bl2tr": AnyView(ZStack { BackgroundGroup.crimson2rose_bl2tr }),
        "cyan2green_r2l": AnyView(ZStack { BackgroundGroup.cyan2green_r2l }),
        "emerald2jade_bl2tr": AnyView(ZStack { BackgroundGroup.emerald2jade_bl2tr }),
        "forest2lime_t2b": AnyView(ZStack { BackgroundGroup.forest2lime_t2b }),
        "fuchsia2purple_t2b": AnyView(ZStack { BackgroundGroup.fuchsia2purple_t2b }),
        "gold2silver_l2r": AnyView(ZStack { BackgroundGroup.gold2silver_l2r }),
        "gray2white_tl2br": AnyView(ZStack { BackgroundGroup.gray2white_tl2br }),
        "green2blue_tl2br": AnyView(ZStack { BackgroundGroup.green2blue_tl2br }),
        "green2cyan_tl2br": AnyView(ZStack { BackgroundGroup.green2cyan_tl2br }),
        "green2yellow_br2tl": AnyView(ZStack { BackgroundGroup.green2yellow_br2tl }),
        "indigo2blue_t2b": AnyView(ZStack { BackgroundGroup.indigo2blue_t2b }),
        "khaki2olive_l2r": AnyView(ZStack { BackgroundGroup.khaki2olive_l2r }),
        "lavender2purple_t2b": AnyView(ZStack { BackgroundGroup.lavender2purple_t2b }),
        "lemon2lime_l2r": AnyView(ZStack { BackgroundGroup.lemon2lime_l2r }),
        "magenta2pink_r2l": AnyView(ZStack { BackgroundGroup.magenta2pink_r2l }),
        "maroon2red_bl2tr": AnyView(ZStack { BackgroundGroup.maroon2red_bl2tr }),
        "mint2teal_tl2br": AnyView(ZStack { BackgroundGroup.mint2teal_tl2br }),
        "navy2skyblue_bl2tr": AnyView(ZStack { BackgroundGroup.navy2skyblue_bl2tr }),
        "olive2lime_r2l": AnyView(ZStack { BackgroundGroup.olive2lime_r2l }),
        "orange2yellow_tl2br": AnyView(ZStack { BackgroundGroup.orange2yellow_tl2br }),
        "peach2cream_t2b": AnyView(ZStack { BackgroundGroup.peach2cream_t2b }),
        "pink2purple_t2b": AnyView(ZStack { BackgroundGroup.pink2purple_t2b }),
        "plum2lavender_t2b": AnyView(ZStack { BackgroundGroup.plum2lavender_t2b }),
        "purple2pink_tl2br": AnyView(ZStack { BackgroundGroup.purple2pink_tl2br }),
        "purple2red_b2t": AnyView(ZStack { BackgroundGroup.purple2red_b2t }),
        "red2orange_tl2br": AnyView(ZStack { BackgroundGroup.red2orange_tl2br }),
        "red2yellow_tl2br": AnyView(ZStack { BackgroundGroup.red2yellow_tl2br }),
        "rose2coral_l2r": AnyView(ZStack { BackgroundGroup.rose2coral_l2r }),
        "ruby2garnet_t2b": AnyView(ZStack { BackgroundGroup.ruby2garnet_t2b }),
        "salmon2peach_l2r": AnyView(ZStack { BackgroundGroup.salmon2peach_l2r }),
        "sapphire2aqua_t2b": AnyView(ZStack { BackgroundGroup.sapphire2aqua_t2b }),
        "seagreen2turquoise_bl2tr": AnyView(ZStack { BackgroundGroup.seagreen2turquoise_bl2tr }),
        "sienna2tan_r2l": AnyView(ZStack { BackgroundGroup.sienna2tan_r2l }),
        "slate2gray_t2b": AnyView(ZStack { BackgroundGroup.slate2gray_t2b }),
        "sunflower2marigold_bl2tr": AnyView(ZStack { BackgroundGroup.sunflower2marigold_bl2tr }),
        "turquoise2aqua_l2r": AnyView(ZStack { BackgroundGroup.turquoise2aqua_l2r }),
        "violet2indigo_r2l": AnyView(ZStack { BackgroundGroup.violet2indigo_r2l }),
        "yellow2blue_tl2br": AnyView(ZStack { BackgroundGroup.yellow2blue_tl2br }),
        "yellow2green_bl2tr": AnyView(ZStack { BackgroundGroup.yellow2green_bl2tr }),
    ]

    // MARK: amber2orange-t2b
    static var amber2orange_t2b: some View {
        from2(.init(red: 1, green: 0.75, blue: 0), .orange, .top, .bottom)
    }

    // MARK: aquamarine2teal_l2r
    static var aquamarine2teal_l2r: some View {
        from2(.init(red: 0.5, green: 1.0, blue: 0.83), .teal, .leading, .trailing)
    }

    // MARK: beige2brown_tl2br
    static var beige2brown_tl2br: some View {
        from2(.init(red: 0.96, green: 0.96, blue: 0.86), .brown, .topLeading, .bottomTrailing)
    }

    // MARK: black2white-tl2br
    static var black2white_tl2br: some View {
        from2(.black, .white, .topLeading, .bottomTrailing)
    }

    // MARK: blue2clear-tl2br
    static var blue2clear_tl2br: some View {
        from2(.blue, .clear, .topLeading, .bottomTrailing)
    }

    // MARK: blue2cyan
    static var blue2cyan: some View {
        from2(.blue, .cyan, .top, .bottom)
    }

    // MARK: blue2green
    static var blue2green: some View {
        from2(.blue, .green, .top, .bottom)
    }

    // MARK: blue2indigo-tl2br
    static var blue2indigo_tl2br: some View {
        from2(.blue, .indigo, .topLeading, .bottomTrailing)
    }

    // MARK: blue2purple-l2r
    static var blue2purple_l2r: some View {
        from2(.blue, .purple, .leading, .trailing)
    }

    // MARK: blue2white-center
    static var blue2white_center: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [.blue, .white]),
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
        }.ignoresSafeArea()
    }

    // MARK: blue2yellow-tl2br
    static var blue2yellow_tl2br: some View {
        from2(.blue, .yellow, .topLeading, .bottomTrailing)
    }

    // MARK: brown2orange-l2r
    static var brown2orange_l2r: some View {
        from2(.brown, .orange, .leading, .trailing)
    }

    // MARK: burgundy2pink_bl2tr
    static var burgundy2pink_bl2tr: some View {
        from2(.init(red: 0.5, green: 0, blue: 0.13), .pink, .bottomLeading, .topTrailing)
    }

    // MARK: charcoal2silver_r2l
    static var charcoal2silver_r2l: some View {
        from2(.init(red: 0.21, green: 0.27, blue: 0.31), .init(red: 0.75, green: 0.75, blue: 0.75), .trailing, .leading)
    }

    // MARK: coral2peach-t2b
    static var coral2peach_t2b: some View {
        from2(.init(red: 1, green: 0.5, blue: 0.31), .init(red: 1, green: 0.89, blue: 0.71), .top, .bottom)
    }

    // MARK: crimson2rose-bl2tr
    static var crimson2rose_bl2tr: some View {
        from2(.init(red: 0.86, green: 0.08, blue: 0.24), .init(red: 1, green: 0, blue: 0.5), .bottomLeading, .topTrailing)
    }

    // MARK: cyan2green-r2l
    static var cyan2green_r2l: some View {
        from2(.cyan, .green, .trailing, .leading)
    }

    // MARK: emerald2jade-bl2tr
    static var emerald2jade_bl2tr: some View {
        from2(.init(red: 0.31, green: 0.78, blue: 0.47), .init(red: 0, green: 0.66, blue: 0.42), .bottomLeading, .topTrailing)
    }

    // MARK: forest2lime_t2b
    static var forest2lime_t2b: some View {
        from2(.init(red: 0.13, green: 0.55, blue: 0.13), .init(red: 0.2, green: 0.8, blue: 0.2), .top, .bottom)
    }

    // MARK: fuchsia2purple-t2b
    static var fuchsia2purple_t2b: some View {
        from2(.init(red: 1, green: 0, blue: 1), .purple, .top, .bottom)
    }

    // MARK: gold2silver-l2r
    static var gold2silver_l2r: some View {
        from2(.init(red: 1, green: 0.84, blue: 0), .init(red: 0.75, green: 0.75, blue: 0.75), .leading, .trailing)
    }

    // MARK: gray2white-tl2br
    static var gray2white_tl2br: some View {
        from2(.gray, .white, .topLeading, .bottomTrailing)
    }

    // MARK: green2blue-tl2br
    static var green2blue_tl2br: some View {
        from2(.green, .blue, .topLeading, .bottomTrailing)
    }

    // MARK: green2cyan-tl2br
    static var green2cyan_tl2br: some View {
        from2(.green, .cyan, .topLeading, .bottomTrailing)
    }

    // MARK: green2yellow-br2tl
    static var green2yellow_br2tl: some View {
        from2(.green, .yellow, .bottomTrailing, .topLeading)
    }

    // MARK: indigo2blue-t2b
    static var indigo2blue_t2b: some View {
        from2(.indigo, .blue, .top, .bottom)
    }

    // MARK: khaki2olive_l2r
    static var khaki2olive_l2r: some View {
        from2(.init(red: 0.94, green: 0.9, blue: 0.55), .init(red: 0.5, green: 0.5, blue: 0), .leading, .trailing)
    }

    // MARK: lavender2purple-t2b
    static var lavender2purple_t2b: some View {
        from2(.init(red: 0.9, green: 0.9, blue: 0.98), .purple, .top, .bottom)
    }

    // MARK: lemon2lime_l2r
    static var lemon2lime_l2r: some View {
        from2(.init(red: 1, green: 0.97, blue: 0), .init(red: 0.75, green: 1, blue: 0), .leading, .trailing)
    }

    // MARK: magenta2pink-r2l
    static var magenta2pink_r2l: some View {
        from2(.init(red: 1, green: 0, blue: 1), .init(red: 1, green: 0.75, blue: 0.8), .trailing, .leading)
    }

    // MARK: maroon2red-bl2tr
    static var maroon2red_bl2tr: some View {
        from2(.init(red: 0.5, green: 0, blue: 0), .red, .bottomLeading, .topTrailing)
    }

    // MARK: mint2teal-tl2br
    static var mint2teal_tl2br: some View {
        from2(.mint, .teal, .topLeading, .bottomTrailing)
    }

    // MARK: navy2skyblue-bl2tr
    static var navy2skyblue_bl2tr: some View {
        from2(.init(red: 0, green: 0, blue: 0.5), .init(red: 0.53, green: 0.81, blue: 0.92), .bottomLeading, .topTrailing)
    }

    // MARK: olive2lime-r2l
    static var olive2lime_r2l: some View {
        from2(.init(red: 0.5, green: 0.5, blue: 0), .init(red: 0.75, green: 1, blue: 0), .trailing, .leading)
    }

    // MARK: orange2yellow-tl2br
    static var orange2yellow_tl2br: some View {
        from2(.orange, .yellow, .topLeading, .bottomTrailing)
    }

    // MARK: peach2cream_t2b
    static var peach2cream_t2b: some View {
        from2(.init(red: 1, green: 0.89, blue: 0.71), .init(red: 1, green: 0.99, blue: 0.82), .top, .bottom)
    }

    // MARK: pink2purple-t2b
    static var pink2purple_t2b: some View {
        from2(.pink, .purple, .top, .bottom)
    }

    // MARK: plum2lavender-t2b
    static var plum2lavender_t2b: some View {
        from2(.init(red: 0.87, green: 0.63, blue: 0.87), .init(red: 0.9, green: 0.9, blue: 0.98), .top, .bottom)
    }

    // MARK: purple2pink-tl2br
    static var purple2pink_tl2br: some View {
        from2(.purple, .pink, .topLeading, .bottomTrailing)
    }

    // MARK: purple2red-b2t
    static var purple2red_b2t: some View {
        from2(.purple, .red, .bottom, .top)
    }

    // MARK: red2orange-tl2br
    static var red2orange_tl2br: some View {
        from2(.red, .orange, .topLeading, .bottomTrailing)
    }

    // MARK: red2yellow-tl2br
    static var red2yellow_tl2br: some View {
        from2(.red, .yellow, .topLeading, .bottomTrailing)
    }

    // MARK: rose2coral_l2r
    static var rose2coral_l2r: some View {
        from2(.init(red: 1, green: 0, blue: 0.5), .init(red: 1, green: 0.5, blue: 0.31), .leading, .trailing)
    }

    // MARK: ruby2garnet_t2b
    static var ruby2garnet_t2b: some View {
        from2(.init(red: 0.88, green: 0.07, blue: 0.37), .init(red: 0.64, green: 0.08, blue: 0.18), .top, .bottom)
    }

    // MARK: salmon2peach-l2r
    static var salmon2peach_l2r: some View {
        from2(.init(red: 0.98, green: 0.5, blue: 0.45), .init(red: 1, green: 0.89, blue: 0.71), .leading, .trailing)
    }

    // MARK: sapphire2aqua-t2b
    static var sapphire2aqua_t2b: some View {
        from2(.init(red: 0.06, green: 0.32, blue: 0.73), .init(red: 0, green: 1, blue: 1), .top, .bottom)
    }

    // MARK: seagreen2turquoise_bl2tr
    static var seagreen2turquoise_bl2tr: some View {
        from2(.init(red: 0.18, green: 0.55, blue: 0.34), .init(red: 0.25, green: 0.88, blue: 0.82), .bottomLeading, .topTrailing)
    }

    // MARK: sienna2tan_r2l
    static var sienna2tan_r2l: some View {
        from2(.init(red: 0.63, green: 0.32, blue: 0.18), .init(red: 0.82, green: 0.71, blue: 0.55), .trailing, .leading)
    }

    // MARK: slate2gray_t2b
    static var slate2gray_t2b: some View {
        from2(.init(red: 0.44, green: 0.5, blue: 0.56), .gray, .top, .bottom)
    }

    // MARK: sunflower2marigold_bl2tr
    static var sunflower2marigold_bl2tr: some View {
        from2(.init(red: 1, green: 0.84, blue: 0), .init(red: 0.91, green: 0.59, blue: 0), .bottomLeading, .topTrailing)
    }

    // MARK: turquoise2aqua-l2r
    static var turquoise2aqua_l2r: some View {
        from2(.init(red: 0.25, green: 0.88, blue: 0.82), .init(red: 0, green: 1, blue: 1), .leading, .trailing)
    }

    // MARK: violet2indigo-r2l
    static var violet2indigo_r2l: some View {
        from2(.init(red: 0.93, green: 0.51, blue: 0.93), .indigo, .trailing, .leading)
    }

    // MARK: yellow2blue-tl2br
    static var yellow2blue_tl2br: some View {
        from2(.yellow, .blue, .topLeading, .bottomTrailing)
    }

    // MARK: yellow2green-bl2tr
    static var yellow2green_bl2tr: some View {
        from2(.yellow, .green, .bottomLeading, .topTrailing)
    }

    private static func from2(_ from: Color, _ to: Color, _ start: UnitPoint, _ end: UnitPoint) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        from,
                        to,
                    ]),
                startPoint: start,
                endPoint: end
            )
        }.ignoresSafeArea()
    }
}

#Preview {
    ScrollView {
        HStack {
            ForEach(1 ... 10, id: \.self) { i in
                let opacity = Double(i) / 10.0
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
    }
    .frame(width: 1200)
    .frame(height: 800)
}
