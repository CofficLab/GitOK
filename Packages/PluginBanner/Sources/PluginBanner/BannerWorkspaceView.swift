import AppKit
import ProviderProjects
import SwiftUI

@MainActor
public struct BannerWorkspaceView: View {
    @StateObject private var model: BannerWorkspaceModel

    public init(projects: any ProjectProviding, repository: BannerRepository = BannerRepository()) {
        _model = StateObject(wrappedValue: BannerWorkspaceModel(projects: projects, repository: repository))
    }

    public var body: some View {
        Group {
            if model.currentProject == nil {
                ContentUnavailableView("No Project", systemImage: "folder", description: Text("Open a project to create banners."))
            } else {
                HStack(spacing: 0) {
                    bannerList
                        .frame(minWidth: 180, idealWidth: 220, maxWidth: 260)
                    Divider()
                    editor
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bannerList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Banners").font(.headline)
                Spacer()
                Button(action: model.createBanner) { Image(systemName: "plus") }
                    .help("New Banner")
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            if model.banners.isEmpty {
                ContentUnavailableView("No Banners", systemImage: "rectangle.on.rectangle", description: Text("Create a banner to get started."))
            } else {
                List(model.banners, selection: Binding(
                    get: { model.selectedBannerID },
                    set: { model.selectBanner(id: $0) }
                )) { banner in
                    Text(banner.id.split(separator: "/").last.map(String.init) ?? banner.id)
                        .tag(Optional(banner.id))
                }
                .listStyle(.sidebar)
            }
        }
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Banner Editor").font(.title2.bold())
                    Spacer()
                    Button("Import Image", action: chooseImage)
                    Button("Export PNG", action: chooseStandardExportFolder)
                    Button("Mac Store", action: chooseMacExportFolder)
                    Button("iPhone Store", action: chooseIPhoneExportFolder)
                    Button("Delete", role: .destructive, action: model.deleteSelectedBanner)
                    Button("Save", action: model.saveDraft)
                        .buttonStyle(.borderedProminent)
                }

                Picker("Template", selection: $model.templateID) {
                    Text("Classic").tag(BannerTemplateID.classic)
                    Text("Minimal").tag(BannerTemplateID.minimal)
                }
                .pickerStyle(.segmented)

                TextField("Title", text: $model.title)
                    .textFieldStyle(.roundedBorder)
                if model.templateID == BannerTemplateID.classic {
                    TextField("Subtitle", text: $model.subTitle)
                        .textFieldStyle(.roundedBorder)
                    TextField("Features, one per line", text: $model.featuresText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...8)
                }
                Picker("Background", selection: $model.backgroundID) {
                    Text("Blue").tag("1")
                    Text("Purple").tag("2")
                    Text("Orange").tag("3")
                }
                Slider(value: $model.opacity, in: 0.2...1) {
                    Text("Opacity")
                }
                BannerRenderView(configuration: model.renderConfiguration)
                .frame(maxWidth: .infinity, minHeight: 240)
            }
            .padding(24)
        }
    }

    private func chooseStandardExportFolder() {
        chooseExportFolder(named: "Banner-Standard-PNG") { model.exportStandardPNG(to: $0) }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .webP]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            model.importImage(from: url)
        }
    }

    private func chooseMacExportFolder() {
        chooseExportFolder(named: "Banner-AppStore-Screenshots") { model.exportMacAppStoreScreenshots(to: $0) }
    }

    private func chooseIPhoneExportFolder() {
        chooseExportFolder(named: "Banner-iPhone-AppStore-Screenshots") { model.exportIPhoneAppStoreScreenshots(to: $0) }
    }

    private func chooseExportFolder(named name: String, completion: (URL) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = name
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            completion(url)
        }
    }
}
