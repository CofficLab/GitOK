import Foundation
import ProviderProjects

@MainActor
public final class BannerWorkspaceModel: ObservableObject {
    @Published public private(set) var banners: [BannerFile] = []
    @Published public private(set) var selectedBannerID: String?
    @Published public var templateID = BannerTemplateID.classic
    @Published public var title = "Banner Title"
    @Published public var subTitle = "Banner SubTitle"
    @Published public var featuresText = ""
    @Published public var backgroundID = "1"
    @Published public var opacity = 1.0
    @Published public private(set) var message: String?

    private let projects: any ProjectProviding
    private let repository: BannerRepository
    private var projectObserver: (any ProjectProvidingObserverHandle)?

    public init(
        projects: any ProjectProviding,
        repository: BannerRepository = BannerRepository()
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
    public var selectedBanner: BannerFile? {
        guard let selectedBannerID else { return nil }
        return banners.first { $0.id == selectedBannerID }
    }

    public func reload() {
        guard let project = projects.currentProject else {
            banners = []
            selectedBannerID = nil
            resetDraft()
            return
        }

        banners = repository.getBanners(from: project.url)
        if let selectedBannerID, banners.contains(where: { $0.id == selectedBannerID }) {
            loadDraft(from: banners.first { $0.id == selectedBannerID })
        } else {
            selectedBannerID = banners.first?.id
            loadDraft(from: banners.first)
        }
    }

    public func selectBanner(id: String?) {
        guard id == nil || banners.contains(where: { $0.id == id }) else { return }
        selectedBannerID = id
        loadDraft(from: selectedBanner)
    }

    public func createBanner() {
        guard let project = projects.currentProject else { return }
        do {
            let banner = try repository.createBanner(in: project.url)
            reload()
            selectedBannerID = banner.id
            loadDraft(from: banner)
            message = "Banner created"
        } catch {
            message = error.localizedDescription
        }
    }

    public func deleteSelectedBanner() {
        guard let banner = selectedBanner else { return }
        do {
            try repository.delete(banner)
            reload()
            message = "Banner deleted"
        } catch {
            message = error.localizedDescription
        }
    }

    public func saveDraft() {
        guard var banner = selectedBanner else { return }
        if templateID == BannerTemplateID.classic {
            banner.classicData = ClassicBannerData(
                title: title,
                subTitle: subTitle,
                features: featuresText
                    .split(separator: "\n")
                    .map(String.init)
                    .filter { !$0.isEmpty },
                backgroundId: backgroundID,
                opacity: opacity
            )
        } else {
            banner.minimalData = MinimalBannerData(
                title: title,
                backgroundId: backgroundID,
                opacity: opacity
            )
        }
        banner.lastSelectedTemplateId = templateID

        do {
            try repository.save(banner)
            reload()
            selectedBannerID = banner.id
            loadDraft(from: banner)
            message = "Banner saved"
        } catch {
            message = error.localizedDescription
        }
    }

    public func exportStandardPNG(to folderURL: URL) {
        do {
            try BannerExporter.exportStandardPNG(configuration: renderConfiguration, to: folderURL)
            message = "Standard PNG banners exported"
        } catch {
            message = error.localizedDescription
        }
    }

    public func exportMacAppStoreScreenshots(to folderURL: URL) {
        do {
            try BannerExporter.exportMacAppStoreScreenshots(configuration: renderConfiguration, to: folderURL)
            message = "Mac App Store screenshots exported"
        } catch {
            message = error.localizedDescription
        }
    }

    public func exportIPhoneAppStoreScreenshots(to folderURL: URL) {
        do {
            try BannerExporter.exportIPhoneAppStoreScreenshots(configuration: renderConfiguration, to: folderURL)
            message = "iPhone App Store screenshots exported"
        } catch {
            message = error.localizedDescription
        }
    }

    public var renderConfiguration: BannerRenderConfiguration {
        BannerRenderConfiguration(
            templateID: templateID,
            title: title,
            subTitle: subTitle,
            features: featuresText.split(separator: "\n").map(String.init).filter { !$0.isEmpty },
            backgroundID: backgroundID,
            opacity: opacity
        )
    }

    private func loadDraft(from banner: BannerFile?) {
        guard let banner else {
            resetDraft()
            return
        }
        templateID = BannerTemplateID.all.contains(banner.lastSelectedTemplateId)
            ? banner.lastSelectedTemplateId
            : BannerTemplateID.classic
        if let data = banner.classicData, templateID == BannerTemplateID.classic {
            title = data.title
            subTitle = data.subTitle
            featuresText = data.features.joined(separator: "\n")
            backgroundID = data.backgroundId
            opacity = data.opacity
        } else if let data = banner.minimalData {
            title = data.title
            subTitle = ""
            featuresText = ""
            backgroundID = data.backgroundId
            opacity = data.opacity
        } else {
            resetDraft()
        }
    }

    private func resetDraft() {
        templateID = BannerTemplateID.classic
        title = "Banner Title"
        subTitle = "Banner SubTitle"
        featuresText = ""
        backgroundID = "1"
        opacity = 1
    }
}
