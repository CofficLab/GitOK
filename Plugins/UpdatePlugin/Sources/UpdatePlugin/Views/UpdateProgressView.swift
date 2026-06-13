import SwiftUI

/// 下载进度视图
public struct UpdateProgressView: View {
    @ObservedObject var downloader: UpdateDownloader

    public init(downloader: UpdateDownloader) {
        self.downloader = downloader
    }

    public var body: some View {
        VStack(spacing: 16) {
            // 进度条
            ProgressView(value: downloader.downloadProgress) {
                Text("正在下载...")
                    .font(.headline)
            } currentValueLabel: {
                Text("\(Int(downloader.downloadProgress * 100))%")
                    .font(.caption)
            }
            .progressViewStyle(.linear)
            .frame(width: 300)

            // 详细信息
            HStack {
                Text(downloader.downloadSpeed)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(formatBytes(downloader.downloadedBytes)) / \(formatBytes(downloader.totalBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 取消按钮
            Button("取消") {
                downloader.cancelDownload()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024 / 1024
        return String(format: "%.1f MB", mb)
    }
}