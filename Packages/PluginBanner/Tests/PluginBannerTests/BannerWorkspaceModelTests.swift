import Foundation
import Testing
@testable import PluginBanner
@testable import ProviderProjects

// MARK: - Fakes

@MainActor
private final class FakeBannerCapability: BannerProjectCapability {
    var currentProject: Project?
    init(project: Project?) { self.currentProject = project }
    func addObserver(_ callback: @escaping (ProjectProvidingEvent) -> Void) -> any ProjectProvidingObserverHandle {
        FakeHandle()
    }
}

private final class FakeHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}

// MARK: - Device / config / error

@MainActor
@Test("banner export device dimensions and prefixes")
func bannerExportDeviceDimensions() {
    #expect(BannerExportDevice.iMac.width == 4480)
    #expect(BannerExportDevice.iMac.height == 2520)
    #expect(BannerExportDevice.MacBook.width == 2880)
    #expect(BannerExportDevice.iPhoneBig.width == 1290)
    #expect(BannerExportDevice.iPhoneSmall.width == 1242)
    #expect(BannerExportDevice.iPad_mini.width == 1488)

    #expect(BannerExportDevice.iMac.filePrefix == "banner")
    #expect(BannerExportDevice.MacBook.filePrefix == "banner")
    #expect(BannerExportDevice.iPhoneBig.filePrefix == "iphone-appstore-screenshot")
    #expect(BannerExportDevice.iPhoneSmall.filePrefix == "iphone-appstore-screenshot")
    #expect(BannerExportDevice.iPad_mini.filePrefix == "banner")

    #expect(BannerExporter.standardDevices.count == 5)
    #expect(BannerExporter.macAppStoreDevices == [.iMac, .MacBook])
    #expect(BannerExporter.iPhoneAppStoreDevices == [.iPhoneBig, .iPhoneSmall])
}

@Test("export error description is non-empty")
func exportErrorDescription() {
    let err = BannerExportError.renderFailed(.iMac)
    #expect(err.errorDescription?.isEmpty == false)
}

@Test("repository image id / url edge cases")
func repositoryImageIDURLEdgeCases() {
    let repo = BannerRepository()
    let projectURL = URL(fileURLWithPath: "/tmp/proj-\(UUID().uuidString)")

    // imageID: no project -> raw path
    #expect(repo.imageID(for: URL(fileURLWithPath: "/elsewhere/a.png"), projectURL: nil) == "/elsewhere/a.png")
    // imageID: inside project -> relative
    #expect(repo.imageID(for: URL(fileURLWithPath: projectURL.path + "/images/a.png"), projectURL: projectURL) == "images/a.png")
    // imageID: outside project -> absolute path returned
    #expect(repo.imageID(for: URL(fileURLWithPath: "/elsewhere/b.png"), projectURL: projectURL) == "/elsewhere/b.png")

    // imageURL: file:// prefix
    #expect(repo.imageURL(for: "file:///tmp/x.png", in: projectURL).absoluteString == "file:///tmp/x.png")
    // imageURL: absolute path that does not exist -> appended relative
    #expect(repo.imageURL(for: "/images/missing.png", in: projectURL).path == projectURL.path + "/images/missing.png")
    // imageURL: relative
    #expect(repo.imageURL(for: "images/a.png", in: projectURL).path == projectURL.path + "/images/a.png")
}

@Test("localization wrapper returns non-empty string")
func localizationWrapper() {
    let s = BannerLocalization.string("Banner created", bundle: .module, locale: Locale(identifier: "en"))
    #expect(s.isEmpty == false)
}

// MARK: - Workspace model

@MainActor
@Test("workspace model resets draft when no project")
func workspaceModelNoProject() {
    let cap = FakeBannerCapability(project: nil)
    let model = BannerWorkspaceModel(capability: cap)
    #expect(model.banners.isEmpty)
    #expect(model.selectedBannerID == nil)
    #expect(model.currentProject == nil)
    #expect(model.selectedBanner == nil)

    // Mutating calls with no project are no-ops and do not crash.
    model.createBanner()
    model.deleteSelectedBanner()
    model.saveDraft()
    #expect(model.banners.isEmpty)
}

@MainActor
@Test("workspace model create / select / delete / save round trip")
func workspaceModelRoundTrip() throws {
    let projectURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("BannerModel-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: projectURL) }
    let project = Project(url: projectURL)

    let cap = FakeBannerCapability(project: project)
    let model = BannerWorkspaceModel(capability: cap)
    #expect(model.banners.isEmpty)

    model.createBanner()
    #expect(model.banners.count == 1)
    #expect(model.selectedBanner != nil)
    #expect(model.message != nil)

    // Edit draft and save (classic branch).
    model.title = "My Banner"
    model.subTitle = "Sub"
    model.featuresText = "F1\nF2\n\nF3"
    model.templateID = BannerTemplateID.classic
    model.saveDraft()

    // Reload from disk: draft should be restored with split features.
    model.reload()
    #expect(model.title == "My Banner")
    #expect(model.featuresText.split(separator: "\n").count == 3)
    #expect(model.renderConfiguration.features == ["F1", "F2", "F3"])

    // Switch to minimal template and save.
    model.templateID = BannerTemplateID.minimal
    model.title = "Mini"
    model.saveDraft()
    model.reload()
    #expect(model.templateID == BannerTemplateID.minimal)
    #expect(model.title == "Mini")

    // selectBanner with unknown id is ignored; with nil clears selection.
    model.selectBanner(id: "does-not-exist")
    #expect(model.selectedBannerID != nil)
    model.selectBanner(id: nil)
    #expect(model.selectedBannerID == nil)

    // Create a second banner, select it, then delete selected.
    model.createBanner()
    #expect(model.banners.count == 2)
    model.deleteSelectedBanner()
    #expect(model.banners.count == 1)
}

@MainActor
@Test("workspace model export paths produce message")
func workspaceModelExportPaths() throws {
    let projectURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("BannerExportModel-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: projectURL) }
    let project = Project(url: projectURL)
    let cap = FakeBannerCapability(project: project)
    let model = BannerWorkspaceModel(capability: cap)
    model.createBanner()

    let out = FileManager.default.temporaryDirectory
        .appendingPathComponent("BannerOut-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: out) }

    model.exportStandardPNG(to: out)
    model.exportMacAppStoreScreenshots(to: out)
    model.exportIPhoneAppStoreScreenshots(to: out)
    // Export should have populated a success message.
    #expect(model.message != nil)
}
