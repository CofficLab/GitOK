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
    @Published public private(set) var message: String?

    private let projects: any ProjectProviding
    private let repository: IconRepository
    private var projectObserver: (any ProjectProvidingObserverHandle)?

    public init(
        projects: any ProjectProviding,
        repository: IconRepository = IconRepository()
    ) {
        self.projects = projects
        self.repository = repository
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
        if let selectedIconID, icons.contains(where: { $0.id == selectedIconID }) {
            loadDraft(from: selectedIcon)
        } else {
            selectedIconID = icons.first?.id
            loadDraft(from: icons.first)
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
    }
}
