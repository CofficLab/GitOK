import AppKit
import AVKit
import LumiUI
import PDFKit
import SwiftUI

struct GitBinaryPreviewView: View {
    let kind: GitDiffContentKind
    let data: Data
    let path: String
    @LumiTheme private var theme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: kind.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title)
                        .font(.appBodyEmphasized)
                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)) · \(path)")
                        .font(.appCaption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    openInDefaultApp()
                } label: {
                    Label("Open", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            AppDivider()

            switch kind {
            case .pdf:
                if let document = PDFDocument(data: data) {
                    PDFDocumentPreview(document: document)
                } else {
                    unsupportedPreview
                }
            case .image:
                if let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    unsupportedPreview
                }
            case .audio, .video:
                MediaFilePreview(kind: kind, data: data)
            case .office, .binary:
                unsupportedPreview
            }
        }
        .background(theme.surface)
    }

    private var unsupportedPreview: some View {
        VStack(spacing: 12) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            Text(kind.title)
                .font(.appBodyEmphasized)
            Text("This binary file cannot be rendered inline yet. Open it in its default macOS app to inspect the contents.")
                .font(.appBody)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Open in Default App") {
                openInDefaultApp()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private func openInDefaultApp() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOK-DiffPreview", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let destination = directory.appendingPathComponent(filename.isEmpty ? "preview.bin" : filename)
        do {
            try data.write(to: destination, options: .atomic)
            NSWorkspace.shared.open(destination)
        } catch {
            // The preview remains available even when the default-app handoff fails.
        }
    }
}

private struct PDFDocumentPreview: NSViewRepresentable {
    let document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .windowBackgroundColor
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document !== document {
            nsView.document = document
        }
    }
}

struct GitPDFComparisonPreview: View {
    let currentData: Data?
    let previousData: Data?
    let path: String
    @State private var showingPrevious = false
    @LumiTheme private var theme

    private var displayedData: Data? {
        showingPrevious ? previousData : currentData
    }

    private var changeTitle: String {
        switch (currentData != nil, previousData != nil) {
        case (true, true): "PDF Change Preview"
        case (true, false): "Added PDF"
        case (false, true): "Deleted PDF"
        default: "PDF Preview"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(changeTitle)
                        .font(.appBodyEmphasized)
                    Text(summary)
                        .font(.appCaption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
            if currentData != nil, previousData != nil {
                    Picker("Version", selection: $showingPrevious) {
                        Text("New").tag(false)
                        Text("Previous").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                Button {
                    openInDefaultApp()
                } label: {
                    Label("Open", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            AppDivider()

            if let displayedData, let document = PDFDocument(data: displayedData) {
                PDFDocumentPreview(document: document)
            } else {
                AppEmptyState(
                    icon: "doc.richtext",
                    title: "PDF Preview Unavailable",
                    description: "The selected version is not a valid PDF document."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(theme.surface)
    }

    private var summary: String {
        let currentPages = currentData.flatMap { PDFDocument(data: $0)?.pageCount }
        let previousPages = previousData.flatMap { PDFDocument(data: $0)?.pageCount }
        switch (currentPages, previousPages) {
        case let (current?, previous?):
            return "\(current) pages now · \(previous) pages before · \(path)"
        case let (current?, nil):
            return "\(current) pages · new file · \(path)"
        case let (nil, previous?):
            return "\(previous) pages · removed file · \(path)"
        default:
            return path
        }
    }

    private func openInDefaultApp() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOK-DiffPreview", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let destination = directory.appendingPathComponent(filename.isEmpty ? "preview.pdf" : filename)
        let data = showingPrevious ? previousData : currentData
        guard let data else { return }
        do {
            try data.write(to: destination, options: .atomic)
            NSWorkspace.shared.open(destination)
        } catch {
            // The inline preview remains available when opening externally fails.
        }
    }
}

private struct MediaFilePreview: View {
    let kind: GitDiffContentKind
    let data: Data
    @State private var mediaURL: URL?

    var body: some View {
        Group {
            if let mediaURL {
                VideoPlayer(player: AVPlayer(url: mediaURL))
                    .padding(20)
            } else {
                MediaPreviewSkeletonView(kind: kind)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard mediaURL == nil else { return }
            let ext = kind == .audio ? "m4a" : "mp4"
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("gitok-diff-\(UUID().uuidString).\(ext)")
            do {
                try data.write(to: url, options: .atomic)
                mediaURL = url
            } catch {
                mediaURL = nil
            }
        }
        .onDisappear {
            if let mediaURL {
                try? FileManager.default.removeItem(at: mediaURL)
            }
        }
    }
}

private struct MediaPreviewSkeletonView: View {
    let kind: GitDiffContentKind

    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.textSecondary.opacity(0.08))
                    .frame(maxWidth: .infinity, minHeight: 180)

                Image(systemName: kind.systemImage)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(theme.textSecondary.opacity(0.35))
            }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(theme.textSecondary.opacity(0.13))
                .frame(width: 156, height: 12)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(
            motionPreference.allowsMotion
                ? (isBreathing ? 0.58 : 0.86)
                : 0.72
        )
        .animation(
            motionPreference.allowsMotion
                ? .easeInOut(duration: 1.15).repeatForever(autoreverses: true)
                : nil,
            value: isBreathing
        )
        .onAppear {
            isBreathing = motionPreference.allowsMotion
        }
        .onChange(of: motionPreference.allowsMotion) { _, allowsMotion in
            isBreathing = allowsMotion
        }
        .accessibilityHidden(true)
    }
}
