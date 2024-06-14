import SwiftUI

struct BanneriPhone: View {
    @State var isEditingTitle = false
    @State var isEditingSubTitle = false

    @Binding var banner: BannerModel

    var body: some View {
        VStack(spacing: 0, content: {
            getTitle().padding()
            Spacer()
            getContent().frame(maxHeight: .infinity)
        })
        .background(BackgroundView.all[banner.backgroundId])
    }

    // MARK: 主标题与副标题

    private func getTitle() -> some View {
        VStack {
            Text(banner.title)
                .font(.system(size: 200))
                .padding(.bottom, 50)
            Text(banner.subTitle)
                .font(.system(size: 100))
                .padding(.bottom, 50)
        }
    }

    // MARK: 右侧的视图

    private func getContent() -> some View {
        ZStack {
            if banner.inScreen {
                ScreeniPhone(content: {
                    banner.getImage().resizable().scaledToFit()
                })
            } else {
                switch banner.getDevice().type {
                case .Mac:
                    banner.getImage().resizable()
                        .scaledToFit()
                case .iPhone:
                    banner.getImage().resizable()
                        .scaledToFit()
                case .iPad:
                    banner.getImage().resizable()
                        .scaledToFit()
                }
            }
        }
    }
}

#Preview("1号") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
