import SwiftUI

struct BannerMaker: View {
    @EnvironmentObject var app: AppManager
    @Binding var snapshotTapped: Bool
    @State var visible = false
    
    var onMessage: (_ message: String) -> Void
    var width: CGFloat = 1024
    var height: CGFloat = 1024
    var url: URL? = nil
    var iconId: String? = nil
    var imageURL: URL?
    var backgroundId: String

    var device: Device
    var title: String
    var subTitle: String
    var badges: [String]
    var inScreen: Bool

    @MainActor private var imageSize: String {
        "\(ImageHelper.getViewWidth(content)) X \(ImageHelper.getViewHeigth(content))"
    }
    
    var image: Image {
        var image = Image("Snapshot-1")
        
        if device == .iPad {
            image = Image("Snapshot-iPad")
        }

        if let url = imageURL, let data = try? Data(contentsOf: url),
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
                    //.overlay { ViewHelper.dashedBorder }
                    .padding(.all, 20)
                Spacer()
            }
            Spacer()
        }
        .onChange(of: snapshotTapped, {
            if snapshotTapped {
                onMessage(ImageHelper.snapshot(content, title: "\(device.rawValue)-\(self.getTimeString())"))
                self.snapshotTapped = false
            }
        })
    }

    private var content: some View {
        ZStack {
            Banner(
                device: device,
                title: title,
                subTitle:
                subTitle,
                inScreen:
                inScreen,
                badges: badges,
                image: image
            )
        }
        .foregroundStyle(.white)
        .frame(width: device.width, height: device.height)
        .background(BackgroundView.all[backgroundId])
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
