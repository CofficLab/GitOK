import SwiftUI

struct BanneriPad: View {
    var url: URL? = nil
    var iconId: String? = nil
    var device: Device
    var title: String
    var subTitle: String
    var inScreen: Bool = true
    var badges: [String]
    var image: Image

    var body: some View {
        VStack(spacing: 20) {
            getTitle()

            GeometryReader { geo in
                HStack {
                    getBadges()
                        .frame(width: geo.size.width * 0.25)
                    getContent()
//                        .background(.green.opacity(0.5))
                }
            }
        }
    }

    // MARK: 主标题与副标题

    private func getTitle() -> some View {
        VStack {
            Text(title)
                .font(.system(size: 200))
                .padding(.top, 100)
                .padding(.vertical, 20)
            Text(subTitle)
                .font(.system(size: 100))
                .padding(.bottom, 100)
        }
    }

    // MARK: 描述特性的小块

    private func getBadges() -> some View {
        VStack(spacing: 50) {
            ForEach(badges, id: \.self) { badge in
                Badge(title: badge)
            }
        }
    }

    // MARK: 右侧的视图

    private func getContent() -> some View {
        ZStack {
            if inScreen {
                ScreeniPad(content: {
                    image.resizable().scaledToFit()
                })
            } else {
                image.resizable()
                    .scaledToFit()
            }
        }
    }
}

#Preview("1号") {
    BannerPreview()
        .frame(width: 800)
        .frame(height: 800)
}
