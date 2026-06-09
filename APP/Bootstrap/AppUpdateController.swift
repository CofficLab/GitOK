import Foundation
import Sparkle

final class AppUpdateController {
    static let shared = AppUpdateController()

    let updaterController: SPUStandardUpdaterController

    var updater: SPUUpdater {
        updaterController.updater
    }

    private let updaterDelegate = UpdaterDelegate()

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: updaterDelegate,
            userDriverDelegate: nil
        )
        updaterController.startUpdater()
    }
}

private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    private static let feedURLBase = "https://raw.githubusercontent.com/CofficLab/GitOK/main"

    func feedURLString(for updater: SPUUpdater) -> String? {
        #if arch(arm64)
        let feedPath = "appcast-arm64.xml"
        #else
        let feedPath = "appcast-x86_64.xml"
        #endif

        return "\(Self.feedURLBase)/\(feedPath)"
    }
}
