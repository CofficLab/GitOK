import AppKit
import Foundation
import GitOKCoreKit
import GitOKSupportKit
import SwiftUI

/**
 简约模板的图片组件
 专门为简约布局设计的图片显示组件
 */
struct MinimalImage: View {
    @EnvironmentObject var b: BannerProvider
    @State private var loadedImage: Image?

    var banner: BannerFile { b.banner }
    var minimalData: MinimalBannerData? { banner.minimalData }
    var image: Image { loadedImage ?? Image("Snapshot-1") }

    var body: some View {
        ZStack {
            if let device = minimalData?.selectedDevice {
                switch device {
                case .iMac:
                    iMacScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .MacBook:
                    MacBookScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhoneBig:
                    iPhoneScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhoneSmall:
                    iPhoneScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPad_mini:
                    iPadScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhone_15:
                    iPhoneScreen(content: {
                        image.resizable().scaledToFit()
                    })
                case .iPhone_SE:
                    iPhoneScreen(content: {
                        image.resizable().scaledToFit()
                    })
                }
            } else {
                image
                    .resizable()
                    .scaledToFit()
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: minimalData?.imageId) {
            loadImage()
        }
        .onChange(of: banner.projectURL) {
            loadImage()
        }
    }

    private func getCornerRadius() -> CGFloat {
        // 简约模板使用较大的圆角
        return 16.0
    }

    private func loadImage() {
        guard let imageId = minimalData?.imageId else {
            loadedImage = nil
            return
        }

        let projectURL = banner.projectURL
        let imageURL = ProjectImage.fromImageId(imageId).getImageURL(projectURL)

        Task.detached(priority: .userInitiated) {
            let data = try? Data(contentsOf: imageURL)
            await MainActor.run {
                guard minimalData?.imageId == imageId, banner.projectURL == projectURL else { return }
                if let data, let nsImage = NSImage(data: data) {
                    loadedImage = Image(nsImage: nsImage)
                } else {
                    loadedImage = nil
                }
            }
        }
    }
}
