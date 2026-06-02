import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public extension URL {
    var isFolder: Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }

    var isFile: Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }

    var isNetworkURL: Bool {
        scheme == "http" || scheme == "https"
    }

    func getContent() throws -> String {
        try String(contentsOf: self, encoding: .utf8)
    }

    @discardableResult
    func createIfNotExist() throws -> URL {
        let parentDirectory = deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDirectory.path) {
            try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        }

        if hasDirectoryPath {
            if !FileManager.default.fileExists(atPath: path) {
                try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
            }
        } else if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }

        return self
    }

    func openFolder() {
        #if os(macOS)
        NSWorkspace.shared.open(self)
        #elseif os(iOS)
        UIApplication.shared.open(self)
        #endif
    }

    func open() {
        openFolder()
    }
}
