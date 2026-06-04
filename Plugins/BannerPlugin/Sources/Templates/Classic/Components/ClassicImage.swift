import AppKit
import Foundation
import GitOKCoreKit
import GitOKSupportKit
import SwiftUI

/**
 经典模板的图片组件
 专门为经典布局设计的图片显示组件
 */
struct ClassicImage: View {
    @EnvironmentObject var b: BannerProvider
    @State private var loadedImage: Image?

    var banner: BannerFile { b.banner }
    var classicData: ClassicBannerData? { banner.classicData }
    var image: Image { loadedImage ?? Image(ClassicBannerData.defaultImageId) }

    var body: some View {
        ZStack {
            if let device = classicData?.selectedDevice {
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
        .onChange(of: classicData?.imageId) {
            loadImage()
        }
        .onChange(of: banner.projectURL) {
            loadImage()
        }
    }

    private func loadImage() {
        guard let imageId = classicData?.imageId else {
            loadedImage = nil
            return
        }

        let projectURL = banner.projectURL
        let cleanPath = imageId.replacingOccurrences(of: "\\/", with: "/")
        let imageURL = URL(fileURLWithPath: projectURL.path).appendingPathComponent(cleanPath)

        Task.detached(priority: .userInitiated) {
            let data = try? Data(contentsOf: imageURL)
            await MainActor.run {
                guard classicData?.imageId == imageId, banner.projectURL == projectURL else { return }
                if let data, let nsImage = NSImage(data: data) {
                    loadedImage = Image(nsImage: nsImage)
                } else {
                    loadedImage = nil
                }
            }
        }
    }
}
