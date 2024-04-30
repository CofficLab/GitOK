import SwiftUI

struct Icon: View {
    var width: CGFloat = 1024
    var height: CGFloat = 1024
    var url: URL? = nil
    var iconId: Int? = nil
    var background: AnyView?

    private var image: Image {
        if let url = url {
            return Image(nsImage: NSImage(data: try! Data(contentsOf: url))!)
        }

        if let id = iconId {
            return IconPng.getImage(id)
        }

        return Image("icon")
    }

    var body: some View {
        ZStack {
            // MARK: 背景色

            background

            HStack {
                image.resizable().scaledToFit()
            }.scaleEffect(1.8)
        }
        .frame(width: width, height: height)
    }
}

#Preview("1号") {
    AppPreview()
}
