import SwiftUI
import UniformTypeIdentifiers
import MagicKit

struct IconMaker: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MessageProvider

    @Binding var snapshotTapped: Bool
    @Binding var icon: IconModel

    private let tag = TimeHelper.getTimeString()
    private var folderName: String { "AppIcon-\(tag).appiconset" }


    @State private var imageSet: [Any] = []
    @State private var folderPath: URL? = nil
    @State private var imageURL: URL? = nil

    var withBorder = false

    var body: some View {
        TabView(content: {
            ImageHelper.makeImage(macOSView)
                .resizable()
                .scaledToFit()
                .overlay {
                    ZStack {
                        if withBorder {
                            ViewHelper.dashedBorder
                        }
                    }
                }
                .tag("macOS")
                .tabItem { Label("macOS", systemImage: "plus") }

            ImageHelper.makeImage(iOSView)
                .resizable()
                .scaledToFit()
                .overlay {
                    ZStack {
                        if withBorder {
                            ViewHelper.dashedBorder
                        }
                    }
                }
                .tag("iOS")
                .tabItem { Label("iOS", systemImage: "plus") }
        })
        .onChange(of: snapshotTapped) {
            if snapshotTapped {
                snapshotMany()
                self.snapshotTapped = false
            }
        }
    }

    var macOSView: some View {
        ZStack {
            // MARK: 背景色

            icon.background

            HStack {
                if let scale = icon.scale {
                    icon.image.scaleEffect(scale)
                } else {
                    icon.image.resizable().scaledToFit()
                }
            }.scaleEffect(1.8)
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerSize: CGSize(
            width: 200,
            height: 200
        ))).padding(100)
    }

    var iOSView: some View {
        ZStack {
            // MARK: 背景色

            icon.background

            HStack {
                if let scale = icon.scale {
                    icon.image.scaleEffect(scale)
                } else {
                    icon.image.resizable().scaledToFit()
                }
            }.scaleEffect(1.8)
        }
    }

    private func getContainerWidth(_ geo: GeometryProxy) -> CGFloat {
        max(geo.size.width, 100)
    }

    private func getContainerHeight(_ geo: GeometryProxy) -> CGFloat {
        max(geo.size.height, 100)
    }

    @MainActor private func snapshotMany() {
        imageSet = []
        var message = ""

        (message, folderPath) = getFolderPath()
        if folderPath == nil {
            m.setFlashMessage(message)
            return
        }

        makeiOSIcon(tag, folder: folderPath!)
        makemacOSIcon(tag, folder: folderPath!)
        makeContentJson(folder: folderPath!)

        m.setFlashMessage("已存储到下载目录")
    }

    @MainActor private func makeContentJson(folder: URL) {
        let jsonData = try! JSONSerialization.data(
            withJSONObject: [
                "images": imageSet,
                "info": [
                    "author": "xcode",
                    "version": 1,
                ],
            ],
            options: [.prettyPrinted]
        )

        try! String(data: jsonData, encoding: .utf8)!.write(
            to: folder.appendingPathComponent("Contents.json"),
            atomically: true,
            encoding: .utf8
        )
    }

    @MainActor private func makemacOSIcon(_ tag: String, folder: URL) {
        for size in [16, 32, 64, 128, 256, 512, 1024] {
            let fileName = "\(tag)-macOS-\(size)x\(size).png"
            let saveTo = folder.appendingPathComponent(fileName)

            _ = ImageHelper.snapshot(
                ImageHelper.makeImage(macOSView)
                    .resizable()
                    .scaledToFit()
                    .frame(width: CGFloat(size), height: CGFloat(size)),
                path: saveTo
            )

            if ![64, 1024].contains(size) {
                imageSet.append([
                    "filename": fileName,
                    "idiom": "mac",
                    "scale": "1x",
                    "size": "\(size)x\(size)",
                ])
            }

            if [64, 256, 512, 1024].contains(size) {
                imageSet.append([
                    "filename": fileName,
                    "idiom": "mac",
                    "scale": "2x",
                    "size": "\(size / 2)x\(size / 2)",
                ])
            }
        }
    }

    @MainActor private func makeiOSIcon(_ tag: String, folder: URL) {
        let size = 1024
        let fileName = "\(tag)-iOS-\(size)x\(size).png"
        let saveTo = folder.appendingPathComponent(fileName)

        _ = ImageHelper.snapshot(
            ImageHelper.makeImage(iOSView)
                .resizable()
                .scaledToFit()
                .frame(width: CGFloat(size), height: CGFloat(size)),
            path: saveTo
        )

        imageSet.append([
            "filename": fileName,
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
        ])
    }

    private func getFolderPath() -> (message: String, path: URL?) {
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return ("无权访问下载文件夹", nil)
        }

        let folderPath = downloadsURL.appendingPathComponent(folderName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: folderPath.path) {
            do {
                try FileManager.default.createDirectory(
                    at: folderPath,
                    withIntermediateDirectories: true
                )
            } catch {
                return ("创建目标目录失败：\(error)", nil)
            }
        }

        return ("成功", folderPath)
    }
}

#Preview("APP") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("APP") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
