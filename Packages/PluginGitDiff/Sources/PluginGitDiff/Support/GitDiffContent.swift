import Foundation
import UniformTypeIdentifiers

enum GitDiffPreviewError: Error, LocalizedError {
    case fileTooLarge(Int)

    var errorDescription: String? {
        switch self {
        case let .fileTooLarge(bytes):
            return "This file is too large for inline preview (\(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))). Open it in its default app instead."
        }
    }
}

enum GitDiffContentKind: Equatable, Sendable {
    case pdf
    case image
    case audio
    case video
    case office
    case binary

    var systemImage: String {
        switch self {
        case .pdf: "doc.richtext"
        case .image: "photo"
        case .audio: "waveform"
        case .video: "film"
        case .office: "doc"
        case .binary: "doc.questionmark"
        }
    }

    var title: String {
        switch self {
        case .pdf: "PDF Preview"
        case .image: "Image Preview"
        case .audio: "Audio File"
        case .video: "Video File"
        case .office: "Office Document"
        case .binary: "Binary File"
        }
    }
}

enum GitDiffContentDetector {
    static func kind(forPath path: String) -> GitDiffContentKind? {
        guard let type = UTType(filenameExtension: URL(fileURLWithPath: path).pathExtension) else {
            return nil
        }
        if type.conforms(to: .pdf) { return .pdf }
        if type.conforms(to: .image) { return .image }
        if type.conforms(to: .audio) { return .audio }
        if type.conforms(to: .movie) { return .video }
        if officeExtensions.contains(URL(fileURLWithPath: path).pathExtension.lowercased()) {
            return .office
        }
        return nil
    }

    static func kind(forPath path: String, data: Data) -> GitDiffContentKind? {
        if data.starts(with: Data("%PDF-".utf8)) {
            return .pdf
        }
        return kind(forPath: path)
    }

    private static let officeExtensions: Set<String> = [
        "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key"
    ]
}
