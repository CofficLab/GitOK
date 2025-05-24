import SwiftUI
import UniformTypeIdentifiers
import MagicCore

struct ScreeniMac<Content>: View where Content: View {
    private let content: Content

    var horizon = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                fullView
            }
            .scaleEffect(getScale(geo), anchor: .topLeading)
            .offset(x:getOffsetX(geo), y:getOffsetY(geo))
        }
    }

    @MainActor var fullView: some View {
        ZStack {
            content
                .frame(width: screenWidth, height: screenHeight)
//                .background(.blue.opacity(0.5))
                .offset(x: 0, y: -580)

            getDeviceImage()
        }
        .frame(width: getDeviceWidth())
        .frame(height: getDeviceHeight())
    }

    private func getDeviceImage() -> Image {
        return
            Image(horizon ? "iPad mini - Starlight - Landscape" : "iMac 27\" - Silver")
    }
    
    // MARK: X的偏移量，用于居中
    
    @MainActor func getOffsetX(_ geo: GeometryProxy) -> CGFloat {
        if getScale(geo) == geo.size.width/getDeviceWidth() {
            return 0
        }
        
        return (geo.size.width-getScale(geo)*getDeviceWidth())*0.5
    }
    
    // MARK: Y的偏移量，用于居中
    
    @MainActor func getOffsetY(_ geo: GeometryProxy) -> CGFloat {
        if getScale(geo) == geo.size.height/getDeviceHeight() {
            return 0
        }
        
        return (geo.size.width-getScale(geo)*getDeviceHeight())*0.5
    }

    // MARK: 设备图片的屏幕的宽度

    var screenWidth: CGFloat {
        horizon ? 2275 : 5120
    }

    // MARK: 设备图片的屏幕的高度

    var screenHeight: CGFloat {
        horizon ? 1500 : 2890
    }
    
    // MARK: 缩放的比例
    
    @MainActor func getScale(_ geo: GeometryProxy) -> CGFloat {
        min(geo.size.width / getDeviceWidth(), geo.size.height / getDeviceHeight())
    }
    
    // MARK: 设备图片的高度

    @MainActor private func getDeviceHeight() -> CGFloat {
        CGFloat(MagicImage.getViewHeigth(getDeviceImage()))
    }

    // MARK: 设备图片的宽度

    @MainActor private func getDeviceWidth() -> CGFloat {
        CGFloat(MagicImage.getViewWidth(getDeviceImage()))
    }

    // MARK: 设备图片的尺寸

    @MainActor private func getDeviceSize() -> String {
        let deviceImage = getDeviceImage()
        return "\(MagicImage.getViewWidth(deviceImage)) X \(MagicImage.getViewHeigth(deviceImage))"
    }

    // MARK: 设备图片的屏幕尺寸

    @MainActor private func getScreenSize() -> String {
        "\(screenWidth) X \(screenHeight)"
    }
}

#Preview("1号") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("iMac") {
    ScreeniMac(content: {
        Text("XXXX")
    })
}

#Preview("iMac") {
    ScreeniMac(content: {
        Text("XXXX")
    }).frame(width: 800, height: 1200)
}
