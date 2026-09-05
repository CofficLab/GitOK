import AppKit
import ProviderProjects
import SwiftUI

@MainActor
public struct IconWorkspaceView: View {
    @StateObject private var model: IconWorkspaceModel

    public init(projects: any ProjectProviding, repository: IconRepository = IconRepository()) {
        _model = StateObject(wrappedValue: IconWorkspaceModel(projects: projects, repository: repository))
    }

    public var body: some View {
        Group {
            if model.currentProject == nil {
                ContentUnavailableView("No Project", systemImage: "folder", description: Text("Open a project to create icons."))
            } else {
                HStack(spacing: 0) {
                    iconList
                        .frame(minWidth: 180, idealWidth: 220, maxWidth: 260)
                    Divider()
                    editor
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Icons").font(.headline)
                Spacer()
                Button(action: model.createIcon) { Image(systemName: "plus") }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            if model.icons.isEmpty {
                ContentUnavailableView("No Icons", systemImage: "app.dashed", description: Text("Create an icon to get started."))
            } else {
                List(model.icons, selection: Binding(
                    get: { model.selectedIconID },
                    set: { model.selectIcon(id: $0) }
                )) { icon in
                    Text(icon.title).tag(Optional(icon.id))
                }
                .listStyle(.sidebar)
            }
        }
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Icon Editor").font(.title2.bold())
                    Spacer()
                    Button("Import Image", action: chooseImage)
                    Button("Export Xcode Sets", action: chooseExportDirectory)
                    Button("Delete", role: .destructive, action: model.deleteSelectedIcon)
                    Button("Save", action: model.saveDraft)
                        .buttonStyle(.borderedProminent)
                }

                TextField("Title", text: $model.title)
                    .textFieldStyle(.roundedBorder)
                Picker("Asset Source", selection: Binding(
                    get: { model.selectedSourceID },
                    set: { model.selectSource($0) }
                )) {
                    ForEach(model.sourceDescriptors) { source in
                        Text(source.title).tag(source.id)
                    }
                }
                .pickerStyle(.segmented)
                sourceAssetPicker
                Picker("Background", selection: $model.backgroundID) {
                    Text("Blue").tag("1")
                    Text("Purple").tag("2")
                    Text("Orange").tag("3")
                }
                Slider(value: $model.scale, in: 0.5...1.5) { Text("Scale") }
                Slider(value: $model.padding, in: 0...0.3) { Text("Padding") }
                Slider(value: $model.opacity, in: 0.2...1) { Text("Opacity") }
                IconPreview(imageURL: model.imageURL, backgroundID: model.backgroundID, scale: model.scale, padding: model.padding, opacity: model.opacity)
                    .frame(maxWidth: .infinity, minHeight: 300)
            }
            .padding(24)
        }
    }

    private var sourceAssetPicker: some View {
        Group {
            if model.sourceAssets.isEmpty {
                Text("No source assets available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(model.sourceAssets) { asset in
                            Button {
                                model.importSourceAsset(asset)
                            } label: {
                                VStack(spacing: 4) {
                                    SourceAssetThumbnail(asset: asset)
                                        .frame(width: 64, height: 64)
                                    Text(asset.title)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                                .frame(width: 76)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            model.importImage(from: url)
        }
    }

    private func chooseExportDirectory() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "AppIcon.appiconset"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            model.exportSelectedIconSets(to: url)
        }
    }
}

private struct SourceAssetThumbnail: View {
    let asset: IconSourceAsset

    var body: some View {
        Group {
            switch asset.payload {
            case let .file(url):
                if let image = NSImage(contentsOf: url) {
                    Image(nsImage: image).resizable().scaledToFit()
                } else {
                    Image(systemName: "photo").font(.title2)
                }
            case let .remote(url):
                AsyncImage(url: url) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFit()
                    } else {
                        Image(systemName: "photo").font(.title2)
                    }
                }
            case let .systemSymbol(symbol):
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
        }
        .padding(6)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct IconPreview: View {
    let imageURL: URL?
    let backgroundID: String
    let scale: Double
    let padding: Double
    let opacity: Double

    var body: some View {
        ZStack {
            background
            if let imageURL, let image = NSImage(contentsOf: imageURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .padding(CGFloat(padding) * 220)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 72))
            }
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 48))
        .opacity(opacity)
    }

    private var background: some View {
        switch backgroundID {
        case "2": LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "3": LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
