import AppKit
import KitGitOKSupport
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
                ContentUnavailableView(BannerLocalization.string("No Project", bundle: .module), systemImage: "folder", description: Text(BannerLocalization.string("Open a project to create banners.", bundle: .module)))
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
                Text(BannerLocalization.string("Banners", bundle: .module)).font(.headline)
                Spacer()
                Button(action: model.createBanner) { Image(systemName: "plus") }
                    .help(BannerLocalization.string("New Banner", bundle: .module))
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            if model.banners.isEmpty {
                ContentUnavailableView(BannerLocalization.string("No Banners", bundle: .module), systemImage: "rectangle.on.rectangle", description: Text(BannerLocalization.string("Create a banner to get started.", bundle: .module)))
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
                    Text(BannerLocalization.string("Banner Editor", bundle: .module)).font(.title2.bold())
                    Spacer()
                    Button(BannerLocalization.string("Import Image", bundle: .module), action: chooseImage)
                    Button(BannerLocalization.string("Export PNG", bundle: .module), action: chooseStandardExportFolder)
                    Button(BannerLocalization.string("Mac Store", bundle: .module), action: chooseMacExportFolder)
                    Button(BannerLocalization.string("iPhone Store", bundle: .module), action: chooseIPhoneExportFolder)
                    Button(BannerLocalization.string("Delete", bundle: .module), role: .destructive, action: model.deleteSelectedBanner)
                    Button(BannerLocalization.string("Save", bundle: .module), action: model.saveDraft)
                        .buttonStyle(.borderedProminent)
                }

                Picker(BannerLocalization.string("Template", bundle: .module), selection: $model.templateID) {
                    Text(BannerLocalization.string("Classic", bundle: .module)).tag(BannerTemplateID.classic)
                    Text(BannerLocalization.string("Minimal", bundle: .module)).tag(BannerTemplateID.minimal)
                }
                .pickerStyle(.segmented)

                TextField(BannerLocalization.string("Title", bundle: .module), text: $model.title)
                    .textFieldStyle(.roundedBorder)
                if model.templateID == BannerTemplateID.classic {
                    TextField(BannerLocalization.string("Subtitle", bundle: .module), text: $model.subTitle)
                        .textFieldStyle(.roundedBorder)
                    TextField(BannerLocalization.string("Features, one per line", bundle: .module), text: $model.featuresText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...8)
                }
                Picker(BannerLocalization.string("Background", bundle: .module), selection: $model.backgroundID) {
                    ForEach(MagicBackgroundGroup.all, id: \.rawValue) { gradient in
                        Text(gradient.displayName).tag(gradient.rawValue)
                    }
                }
                Picker(BannerLocalization.string("Device", bundle: .module), selection: $model.selectedDeviceID) {
                    ForEach(BannerExportDevice.allCases, id: \.rawValue) { device in
                        Text(device.rawValue).tag(device.rawValue)
                    }
                }
                .pickerStyle(.menu)
                Slider(value: $model.opacity, in: 0.2...1) {
                    Text(BannerLocalization.string("Opacity", bundle: .module))
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
