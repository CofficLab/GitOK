import AppKit
import Foundation
import SwiftUI

/// Device sizes retained from the legacy banner generator.
public enum BannerExportDevice: String, CaseIterable, Sendable {
    case iMac
    case MacBook
    case iPhoneBig
    case iPhoneSmall
    case iPad_mini

    public var width: Int {
        switch self {
        case .iMac: 4480
        case .MacBook: 2880
        case .iPhoneBig: 1290
        case .iPhoneSmall: 1242
        case .iPad_mini: 1488
        }
    }

    public var height: Int {
        switch self {
        case .iMac: 2520
        case .MacBook: 1800
        case .iPhoneBig: 2796
        case .iPhoneSmall: 2208
        case .iPad_mini: 2266
        }
    }

    public var filePrefix: String {
        switch self {
        case .iMac, .MacBook: "banner"
        case .iPhoneBig, .iPhoneSmall: "iphone-appstore-screenshot"
        case .iPad_mini: "banner"
        }
    }
}

/// Renders the current banner preview into the PNG batches used by the old UI.
@MainActor
public enum BannerExporter {
    public static let standardDevices: [BannerExportDevice] = BannerExportDevice.allCases
    public static let macAppStoreDevices: [BannerExportDevice] = [.iMac, .MacBook]
    public static let iPhoneAppStoreDevices: [BannerExportDevice] = [.iPhoneBig, .iPhoneSmall]

    public static func exportStandardPNG(
        configuration: BannerRenderConfiguration,
        to folderURL: URL
    ) throws {
        try export(configuration: configuration, devices: standardDevices, to: folderURL)
    }

    public static func exportMacAppStoreScreenshots(
        configuration: BannerRenderConfiguration,
        to folderURL: URL
    ) throws {
        try export(configuration: configuration, devices: macAppStoreDevices, to: folderURL)
    }

    public static func exportIPhoneAppStoreScreenshots(
        configuration: BannerRenderConfiguration,
        to folderURL: URL
    ) throws {
        try export(configuration: configuration, devices: iPhoneAppStoreDevices, to: folderURL)
    }

    private static func export(
        configuration: BannerRenderConfiguration,
        devices: [BannerExportDevice],
        to folderURL: URL
    ) throws {
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        for device in devices {
            var deviceConfiguration = configuration
            deviceConfiguration.deviceID = device.rawValue
            let view = BannerRenderView(configuration: deviceConfiguration)
                .frame(width: CGFloat(device.width), height: CGFloat(device.height))
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else {
                throw BannerExportError.renderFailed(device)
            }

            let fileName = "\(device.filePrefix)-\(device.rawValue)-\(device.width)x\(device.height).png"
            try png.write(to: folderURL.appendingPathComponent(fileName), options: [.atomic])
        }
    }
}

public struct BannerRenderConfiguration: Equatable, Sendable {
    public var templateID: String
    public var title: String
    public var subTitle: String
    public var features: [String]
    public var imageURL: URL?
    public var deviceID: String?
    public var backgroundID: String
    public var opacity: Double

    public init(
        templateID: String,
        title: String,
        subTitle: String = "",
        features: [String] = [],
        imageURL: URL? = nil,
        deviceID: String? = nil,
        backgroundID: String = "1",
        opacity: Double = 1
    ) {
        self.templateID = templateID
        self.title = title
        self.subTitle = subTitle
        self.features = features
        self.imageURL = imageURL
        self.deviceID = deviceID
        self.backgroundID = backgroundID
        self.opacity = opacity
    }
}

public enum BannerExportError: Error, LocalizedError, Equatable {
    case renderFailed(BannerExportDevice)

    public var errorDescription: String? {
        switch self {
        case let .renderFailed(device): String(format: BannerLocalization.string("Unable to render banner for %@.", bundle: .module), device.rawValue)
        }
    }
}
