import SwiftUI

struct BanneriPhone: View {
    var url: URL? = nil
    var iconId: String? = nil
    var device: Device
    var title: String
    var subTitle: String
    var inScreen: Bool = true
    var badges: [String]
    var image: Image

    var body: some View {
        VStack(spacing: 0, content: {
            getTitle().padding()
            Spacer()
            getContent().frame(maxHeight: .infinity)
        })
    }

    // MARK: 主标题与副标题

    private func getTitle() -> some View {
        VStack {
            Text(title)
                .font(.system(size: 200))
                .padding(.bottom, 50)
            Text(subTitle)
                .font(.system(size: 100))
                .padding(.bottom, 50)
        }
    }

    // MARK: 右侧的视图

    private func getContent() -> some View {
        ZStack {
            if inScreen {
                ScreeniPhone(content: {
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

#Preview("1号") {
    BannerPreview()
        .frame(width: 800)
        .frame(height: 800)
}
