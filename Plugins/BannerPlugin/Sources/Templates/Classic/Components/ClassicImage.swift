import AppKit
import Foundation
import GitOKCoreKit
import GitOKSupportKit
import SwiftUI

private struct DecodedClassicBannerImage: @unchecked Sendable {
    let image: NSImage?
}

/**
 经典模板的图片组件
 专门为经典布局设计的图片显示组件
 */
struct ClassicImage: View {
    @EnvironmentObject var b: BannerProvider
    @State private var loadedImage: Image?
    @State private var loadImageTask: Task<Void, Never>?

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
        .onDisappear {
            loadImageTask?.cancel()
            loadImageTask = nil
            loadedImage = nil
        }
    }

    private func loadImage() {
        loadImageTask?.cancel()
        guard let imageId = classicData?.imageId else {
            loadedImage = nil
            return
        }

        let projectURL = banner.projectURL
        let cleanPath = imageId.replacingOccurrences(of: "\\/", with: "/")
        let imageURL = URL(fileURLWithPath: projectURL.path).appendingPathComponent(cleanPath)

        loadImageTask = Task.detached(priority: .userInitiated) {
            let decodedImage = DecodedClassicBannerImage(
                image: BannerImageLoadingRules.previewImage(at: imageURL)
            )
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard classicData?.imageId == imageId, banner.projectURL == projectURL else { return }
                if let nsImage = decodedImage.image {
                    loadedImage = Image(nsImage: nsImage)
                } else {
                    loadedImage = nil
                }
                loadImageTask = nil
            }
        }
    }
}
