import MagicCore
import SwiftUI
import UniformTypeIdentifiers

struct IconMaker: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var i: IconProvider

    @State private var icon: IconModel?

    private let tag = Date.nowCompact
    private var folderName: String { "AppIcon-\(tag).appiconset" }

    @State private var imageSet: [Any] = []
    @State private var folderPath: URL? = nil
    @State private var imageURL: URL? = nil

    var body: some View {
        Group {
            if self.icon != nil {
                HStack {
                    Spacer()
                    VStack {
                        Text("macOS")
                        MagicImage.makeImage(macOSView)
                            .resizable()
                            .scaledToFit()
                    }

                    VStack {
                        Text("iOS")
                        MagicImage.makeImage(iOSView)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    Spacer()
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            self.icon = try? i.getIcon()
        }
        .onNotification(.iconDidSave, perform: { _ in
            self.icon = try? i.getIcon()
        })
        .onChange(of: i.snapshotTapped) {
            if i.snapshotTapped {
                snapshotMany()
                i.snapshotTapped = false
            }
        }
    }

    var macOSView: some View {
        IconPreview(icon: icon!, platform: "macOS")
    }

    var iOSView: some View {
        IconPreview(icon: icon!, platform: "iOS")
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
            m.info(message)
            return
        }

        makeiOSIcon(tag, folder: folderPath!)
        makemacOSIcon(tag, folder: folderPath!)
        makeContentJson(folder: folderPath!)

        m.info("已存储到下载目录")
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

            _ = MagicImage.snapshot(
                MagicImage.makeImage(macOSView)
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

        _ = MagicImage.snapshot(
            MagicImage.makeImage(iOSView)
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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
