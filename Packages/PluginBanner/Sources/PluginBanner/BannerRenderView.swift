import AppKit
import SwiftUI

/// Shared preview/rendering view so the editor and exports cannot drift apart.
public struct BannerRenderView: View {
    public let configuration: BannerRenderConfiguration

    public init(configuration: BannerRenderConfiguration) {
        self.configuration = configuration
    }

    public var body: some View {
        ZStack {
            background
            if isMacDevice {
                HStack(spacing: 24) {
                    textContent
                        .frame(maxWidth: .infinity)
                    imageView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack(spacing: 16) {
                    textContent
                    imageView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(configuration.opacity)
    }

    private var background: some View {
        switch configuration.backgroundID {
        case "2": LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "3": LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var isMacDevice: Bool {
        configuration.deviceID == BannerExportDevice.iMac.rawValue
            || configuration.deviceID == BannerExportDevice.MacBook.rawValue
    }

    @ViewBuilder
    private var textContent: some View {
        if configuration.templateID == BannerTemplateID.classic {
            VStack(spacing: 8) {
                Text(configuration.title).font(.largeTitle.bold())
                Text(configuration.subTitle).font(.title3)
                ForEach(configuration.features, id: \.self) { feature in
                    Text("• \(feature)").font(.callout)
                }
            }
        } else {
            Text(configuration.title).font(.system(size: 42, weight: .bold))
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let imageURL = configuration.imageURL,
           let image = NSImage(contentsOf: imageURL) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        }
    }
}
