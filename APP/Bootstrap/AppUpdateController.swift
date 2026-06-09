import Foundation
import Sparkle

final class AppUpdateController {
    static let shared = AppUpdateController()

    let updaterController: SPUStandardUpdaterController

    var updater: SPUUpdater {
        updaterController.updater
    }

    private static let feedURLBase = "https://raw.githubusercontent.com/CofficLab/GitOK/main"

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        updater.feedURL = Self.feedURL
        updaterController.startUpdater()
    }

    private static var feedURL: URL {
        #if arch(arm64)
        let feedPath = "appcast-arm64.xml"
        #else
        let feedPath = "appcast-x86_64.xml"
        #endif

        return URL(string: "\(feedURLBase)/\(feedPath)")!
    }
}
