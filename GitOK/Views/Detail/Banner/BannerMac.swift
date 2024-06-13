import SwiftUI

struct BannerMac: View {
    var url: URL? = nil
    var iconId: String? = nil
    var device: Device
    var title: String
    var subTitle: String
    var inScreen: Bool = true
    var badges: [String]
    var image: Image

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 0, content: {
                getTitle().frame(height: device.height / 3)
                getBadges().background(.red.opacity(0.0))
                Spacer()
            })
            .background(.red.opacity(0.0)).frame(width: device.width / 3)

            getContent()
                .padding(.trailing, 100)
                .frame(width: device.width / 3 * 2)
                .background(.green.opacity(0.0))
        }
    }

    // MARK: 主标题与副标题

    private func getTitle() -> some View {
        VStack {
            Text(title).font(.system(size: 200))
            Text(subTitle).font(.system(size: 100))
        }
    }

    // MARK: 描述特性的小块

    private func getBadges() -> some View {
        Badges(device: device, badges: badges)
    }

    // MARK: 右侧的视图

    private func getContent() -> some View {
        ZStack {
            if inScreen {
                ScreenMacBook(content: {
                    image.resizable().scaledToFit()
                })
            } else {
                switch device.type {
                case .Mac:
                    image.resizable()
                        .scaledToFit()
                case .iPhone:
                    image.resizable()
                        .scaledToFit()
                case .iPad:
                    image.resizable()
                        .scaledToFit()
                }
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
