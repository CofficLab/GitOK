import SwiftUI

struct BannerLive: View {
    @EnvironmentObject var app: AppManager
    @Binding var snapshotTapped: Bool
    @State var visible = false
    
    var onMessage: (_ message: String) -> Void
    var width: CGFloat = 1024
    var height: CGFloat = 1024
    var banner: BannerModel

    @MainActor private var imageSize: String {
        "\(ImageHelper.getViewWidth(content)) X \(ImageHelper.getViewHeigth(content))"
    }
    
    var image: Image {
        var image = Image("Snapshot-1")
        
        if banner.getDevice() == .iPad {
            image = Image("Snapshot-iPad")
        }

        if let url = banner.imageURL, let data = try? Data(contentsOf: url),
           let nsImage = NSImage(data: data)
        {
            image = Image(nsImage: nsImage)
        }

        return image
    }
    
    var body: some View {
        ZStack {
            if !visible {
                ProgressView()
                    .onAppear {
                        visible = true
                    }
            }
            
            if visible {
                bannerBody
            }
        }
    }

    var bannerBody: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                ImageHelper.makeImage(content)
                    .resizable()
                    .scaledToFit()
                    .padding(.all, 20)
                Spacer()
            }
            Spacer()
        }
        .onChange(of: snapshotTapped, {
            if snapshotTapped {
                onMessage(ImageHelper.snapshot(content, title: "\(banner.device)-\(self.getTimeString())"))
                self.snapshotTapped = false
            }
        })
    }

    private var content: some View {
        ZStack {
            BannerDevice(banner: banner, image: image)
        }
        .foregroundStyle(.white)
        .frame(width: banner.getDevice().width, height: banner.getDevice().height)
        .background(BackgroundView.all[banner.backgroundId])
    }

    private func getTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: Date())
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
