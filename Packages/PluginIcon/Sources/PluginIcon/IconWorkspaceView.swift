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
                ContentUnavailableView(IconLocalization.string("No Project", bundle: .module), systemImage: "folder", description: Text(IconLocalization.string("Open a project to create icons.", bundle: .module)))
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
                Text(IconLocalization.string("Icons", bundle: .module)).font(.headline)
                Spacer()
                Button(action: model.createIcon) { Image(systemName: "plus") }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            if model.icons.isEmpty {
                ContentUnavailableView(IconLocalization.string("No Icons", bundle: .module), systemImage: "app.dashed", description: Text(IconLocalization.string("Create an icon to get started.", bundle: .module)))
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
                    Text(IconLocalization.string("Icon Editor", bundle: .module)).font(.title2.bold())
                    Spacer()
                    Button(IconLocalization.string("Import Image", bundle: .module), action: chooseImage)
                    Button("PNG", action: choosePNGExportDirectory)
                    Button("ImageSet", action: chooseImageSetExportDirectory)
                    Button("Favicon", action: chooseFaviconExportDirectory)
                    Button(IconLocalization.string("Export Xcode Sets", bundle: .module), action: chooseExportDirectory)
                    Button(IconLocalization.string("Delete", bundle: .module), role: .destructive, action: model.deleteSelectedIcon)
                    Button(IconLocalization.string("Save", bundle: .module), action: model.saveDraft)
                        .buttonStyle(.borderedProminent)
                }

                TextField(IconLocalization.string("Title", bundle: .module), text: $model.title)
                    .textFieldStyle(.roundedBorder)
                Picker(IconLocalization.string("Asset Source", bundle: .module), selection: Binding(
                    get: { model.selectedSourceID },
                    set: { model.selectSource($0) }
                )) {
                    ForEach(model.sourceDescriptors) { source in
                        Text(source.title).tag(source.id)
                    }
                }
                .pickerStyle(.segmented)
                Button(IconLocalization.string("Choose Custom Folder", bundle: .module), action: chooseCustomSourceFolder)
                if !model.sourceCategories.isEmpty {
                    Picker(IconLocalization.string("Category", bundle: .module), selection: Binding(
                        get: { model.selectedSourceCategory ?? "all" },
                        set: { model.selectedSourceCategory = $0 == "all" ? nil : $0 }
                    )) {
                        Text(IconLocalization.string("All", bundle: .module)).tag("all")
                        ForEach(model.sourceCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                sourceAssetPicker
                Picker(IconLocalization.string("Background", bundle: .module), selection: $model.backgroundID) {
                    Text(IconLocalization.string("Blue", bundle: .module)).tag("1")
                    Text(IconLocalization.string("Purple", bundle: .module)).tag("2")
                    Text(IconLocalization.string("Orange", bundle: .module)).tag("3")
                }
                Slider(value: $model.scale, in: 0.5...1.5) { Text(IconLocalization.string("Scale", bundle: .module)) }
                Slider(value: $model.padding, in: 0...0.3) { Text(IconLocalization.string("Padding", bundle: .module)) }
                Slider(value: $model.cornerRadius, in: 0...512) { Text(IconLocalization.string("Corner Radius", bundle: .module)) }
                Slider(value: $model.opacity, in: 0.2...1) { Text(IconLocalization.string("Opacity", bundle: .module)) }
                IconPreview(
                    imageURL: model.imageURL,
                    backgroundID: model.backgroundID,
                    scale: model.scale,
                    padding: model.padding,
                    cornerRadius: model.cornerRadius,
                    opacity: model.opacity
                )
                    .frame(maxWidth: .infinity, minHeight: 300)
            }
            .padding(24)
        }
    }

    private var sourceAssetPicker: some View {
        Group {
            if model.sourceAssets.isEmpty {
                Text(IconLocalization.string("No source assets available", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(model.filteredSourceAssets) { asset in
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
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        model.selectedAssetID == asset.id ? Color.accentColor : .clear,
                                        lineWidth: 2
                                    )
                            }
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

    private func chooseCustomSourceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            model.chooseCustomSourceFolder(url)
        }
    }

    private func chooseExportDirectory() {
        chooseExportDirectory(named: "AppIconSets") { model.exportSelectedIconSets(to: $0) }
    }

    private func choosePNGExportDirectory() {
        chooseExportDirectory(named: "PNG") { model.exportPNGSet(to: $0) }
    }

    private func chooseImageSetExportDirectory() {
        chooseExportDirectory(named: "Icon.imageset") { model.exportImageSet(to: $0) }
    }

    private func chooseFaviconExportDirectory() {
        chooseExportDirectory(named: "Favicon") { model.exportFavicon(to: $0) }
    }

    private func chooseExportDirectory(named name: String, completion: (URL) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = name
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            completion(url)
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
    let cornerRadius: Double
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
        .clipShape(RoundedRectangle(cornerRadius: min(max(cornerRadius / 1024 * 280, 0), 140)))
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
