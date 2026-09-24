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
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()

        // `.ts` is ambiguous on macOS: UniformTypeIdentifiers maps it to
        // MPEG-2 transport stream even when the repository file is TypeScript.
        // Defer these files to content inspection instead of treating them as
        // video from the extension alone.
        guard !contentInspectionExtensions.contains(fileExtension) else {
            return nil
        }
        guard let type = UTType(filenameExtension: fileExtension) else {
            return nil
        }
        if type.conforms(to: .pdf) { return .pdf }
        if type.conforms(to: .image) { return .image }
        if type.conforms(to: .audio) { return .audio }
        if type.conforms(to: .movie) { return .video }
        if officeExtensions.contains(fileExtension) {
            return .office
        }
        return nil
    }

    static func needsContentInspection(forPath path: String) -> Bool {
        contentInspectionExtensions.contains(URL(fileURLWithPath: path).pathExtension.lowercased())
    }

    static func kind(forPath path: String, data: Data) -> GitDiffContentKind? {
        if data.starts(with: Data("%PDF-".utf8)) {
            return .pdf
        }
        if isMPEGTransportStream(data) {
            return .video
        }
        if needsContentInspection(forPath: path) {
            return nil
        }
        return kind(forPath: path)
    }

    static func isLikelyText(_ data: Data) -> Bool {
        guard !data.isEmpty else { return true }
        guard !data.contains(0), String(data: data, encoding: .utf8) != nil else {
            return false
        }

        let controlByteCount = data.reduce(into: 0) { count, byte in
            if byte < 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0C && byte != 0x0D {
                count += 1
            }
        }
        return Double(controlByteCount) / Double(data.count) < 0.01
    }

    private static func isMPEGTransportStream(_ data: Data) -> Bool {
        // Standard MPEG-TS packets are 188 bytes. M2TS and FEC variants use
        // 192/204-byte packets, with M2TS adding a four-byte prefix.
        let candidates: [(packetSize: Int, syncOffset: Int)] = [
            (188, 0),
            (192, 4),
            (204, 0)
        ]
        let minimumPacketCount = 5

        return candidates.contains { packetSize, syncOffset in
            let requiredBytes = syncOffset + packetSize * minimumPacketCount
            guard data.count >= requiredBytes else { return false }

            for packetIndex in 0..<minimumPacketCount {
                let offset = syncOffset + packetIndex * packetSize
                guard data[offset] == 0x47 else { return false }

                // Adaptation field control 00 is reserved and invalid for a
                // transport-stream packet, which reduces false positives in
                // ordinary text files.
                guard ((data[offset + 3] >> 4) & 0x03) != 0 else { return false }
            }
            return true
        }
    }

    private static let officeExtensions: Set<String> = [
        "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key"
    ]

    private static let contentInspectionExtensions: Set<String> = ["ts"]
}
