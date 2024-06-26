import Foundation
import OSLog

#if os(macOS)
    import AppKit
#endif

class FileHelper {
    static var fileManager = FileManager.default
    static var label = "📃 FileHelper::"
    
    static func getSize(url: URL) -> Int {
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey])
        let size = resourceValues?.fileSize ?? 0
        print("File size: \(size) bytes")

        return size
    }

    static func showInFinder(url: URL) {
        #if os(macOS)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        #endif
    }

    static func openFolder(url: URL) {
        #if os(macOS)
            NSWorkspace.shared.open(url)
        #endif
    }

    static func isAudioFile(url: URL) -> Bool {
        return ["mp3", "wav", "m4a"].contains(url.pathExtension.lowercased())
    }

    static func isAudioiCloudFile(url: URL) -> Bool {
        let ex = url.pathExtension.lowercased()

        os_log("\(Logger.isMain)🔧 FileHelper::isAudioiCloudFile -> \(ex)")

        return ex == "icloud" && isAudioFile(url: url.deletingPathExtension())
    }

    static func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return fileSize
            } else {
                os_log("Failed to retrieve file size.")
                return 0
            }
        } catch {
            os_log("Error: \(error.localizedDescription)")
            return 0
        }
    }

    static func getFileSizeReadable(_ url: URL) -> String {
        let byteCountFormatter: ByteCountFormatter = {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useGB, .useTB]
            formatter.countStyle = .file
            return formatter
        }()
        
        if !fileManager.fileExists(atPath: url.path) {
            return "-"
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                return byteCountFormatter.string(fromByteCount: fileSize)
            } else {
                print("Failed to retrieve file size.")
                return "-"
            }
        } catch {
            os_log("Error: \(error.localizedDescription)")
            return "-"
        }
    }
}
