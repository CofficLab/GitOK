import Foundation
import ProviderProjects

@MainActor
public final class IconWorkspaceModel: ObservableObject {
    @Published public private(set) var icons: [IconData] = []
    @Published public private(set) var selectedIconID: String?
    @Published public var title = "New Icon"
    @Published public var backgroundID = "1"
    @Published public var opacity = 1.0
    @Published public var scale = 1.0
    @Published public var padding = 0.12
    @Published public private(set) var imageURL: URL?
    @Published public private(set) var sourceAssets: [IconSourceAsset] = []
    @Published public var selectedSourceID = IconSourceID.projectImages
    @Published public private(set) var message: String?

    private let projects: any ProjectProviding
    private let repository: IconRepository
    private let sourceProvider: any IconSourceProviding
    private var projectObserver: (any ProjectProvidingObserverHandle)?

    public init(
        projects: any ProjectProviding,
        repository: IconRepository = IconRepository(),
        sourceProvider: any IconSourceProviding = DefaultIconSourceProvider()
    ) {
        self.projects = projects
        self.repository = repository
        self.sourceProvider = sourceProvider
        projectObserver = projects.addObserver { [weak self] event in
            guard case .selectionChanged = event else { return }
            self?.reload()
        }
        reload()
    }

    public var currentProject: Project? { projects.currentProject }
    public var selectedIcon: IconData? {
        guard let selectedIconID else { return nil }
        return icons.first { $0.id == selectedIconID }
    }

    public func reload() {
        guard let project = projects.currentProject else {
            icons = []
            selectedIconID = nil
            resetDraft()
            return
        }
        icons = repository.getIcons(from: project.url)
        loadSourceAssets(in: project.url)
        if let selectedIconID, icons.contains(where: { $0.id == selectedIconID }) {
            loadDraft(from: selectedIcon)
        } else {
            selectedIconID = icons.first?.id
            loadDraft(from: icons.first)
        }
    }

    public var sourceDescriptors: [IconSourceDescriptor] { sourceProvider.sources }

    public func selectSource(_ sourceID: String) {
        guard sourceProvider.sources.contains(where: { $0.id == sourceID }) else { return }
        selectedSourceID = sourceID
        if let project = projects.currentProject {
            loadSourceAssets(in: project.url)
        }
    }

    public func importSourceAsset(_ asset: IconSourceAsset) {
        guard let project = projects.currentProject else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let importedURL: URL
                switch asset.payload {
                case let .file(url):
                    importedURL = try repository.importImage(url, for: project.url)
                case let .remote(url):
                    importedURL = try await repository.importRemoteImage(url, for: project.url)
                case let .systemSymbol(symbol):
                    importedURL = try repository.importSystemSymbol(symbol, for: project.url)
                }
                imageURL = importedURL
                if selectedIcon == nil { createIcon() }
                saveDraft()
                message = "Icon imported from \(asset.title)"
            } catch {
                message = error.localizedDescription
            }
        }
    }

    public func selectIcon(id: String?) {
        guard id == nil || icons.contains(where: { $0.id == id }) else { return }
        selectedIconID = id
        loadDraft(from: selectedIcon)
    }

    public func createIcon() {
        guard let project = projects.currentProject else { return }
        do {
            let icon = try repository.createIcon(in: project.url)
            reload()
            selectedIconID = icon.id
            loadDraft(from: icon)
            message = "Icon created"
        } catch {
            message = error.localizedDescription
        }
    }

    public func importImage(from sourceURL: URL) {
        guard let project = projects.currentProject else { return }
        do {
            let importedURL = try repository.importImage(sourceURL, for: project.url)
            imageURL = importedURL
            if selectedIcon == nil { createIcon() }
            saveDraft()
            message = "Image imported"
        } catch {
            message = error.localizedDescription
        }
    }

    public func saveDraft() {
        guard var icon = selectedIcon else { return }
        icon.title = title
        icon.backgroundId = backgroundID
        icon.opacity = opacity
        icon.scale = scale
        icon.padding = padding
        icon.imageURL = imageURL
        do {
            try repository.save(icon)
            reload()
            selectedIconID = icon.id
            loadDraft(from: icon)
            message = "Icon saved"
        } catch {
            message = error.localizedDescription
        }
    }

    public func deleteSelectedIcon() {
        guard let icon = selectedIcon else { return }
        do {
            try repository.delete(icon)
            reload()
            message = "Icon deleted"
        } catch {
            message = error.localizedDescription
        }
    }

    public func exportSelectedIcon(to destinationURL: URL) {
        guard var icon = selectedIcon else {
            message = "Import an image before exporting"
            return
        }
        icon.title = title
        icon.backgroundId = backgroundID
        icon.opacity = opacity
        icon.scale = scale
        icon.padding = padding
        icon.imageURL = imageURL
        do {
            try IconExporter.exportAppIcon(from: icon, to: destinationURL)
            message = "AppIcon set exported"
        } catch {
            message = error.localizedDescription
        }
    }

    public func exportSelectedIconSets(to destinationURL: URL) {
        guard var icon = selectedIcon else {
            message = "Import an image before exporting"
            return
        }
        icon.title = title
        icon.backgroundId = backgroundID
        icon.opacity = opacity
        icon.scale = scale
        icon.padding = padding
        icon.imageURL = imageURL
        do {
            try IconExporter.exportXcodeIconSets(from: icon, to: destinationURL)
            message = "Legacy and modern Xcode icon sets exported"
        } catch {
            message = error.localizedDescription
        }
    }

    private func loadDraft(from icon: IconData?) {
        guard let icon else {
            resetDraft()
            return
        }
        title = icon.title
        backgroundID = icon.backgroundId
        opacity = icon.opacity
        scale = icon.scale ?? 1
        padding = icon.padding
        imageURL = icon.imageURL
    }

    private func resetDraft() {
        title = "New Icon"
        backgroundID = "1"
        opacity = 1
        scale = 1
        padding = 0.12
        imageURL = nil
        sourceAssets = []
    }

    private func loadSourceAssets(in projectURL: URL) {
        let sourceID = selectedSourceID
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                sourceAssets = try await sourceProvider.assets(for: sourceID, in: projectURL)
            } catch {
                sourceAssets = []
                message = error.localizedDescription
            }
        }
    }
}
