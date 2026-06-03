import GitOKCoreKit
import SwiftUI

public struct ActivityStatusTile: View {
    private let activityStatus: String?

    public init(activityStatus: String? = nil) {
        self.activityStatus = activityStatus
    }

    public var body: some View {
        if let status = activityStatus, status.isEmpty == false {
            AppStatusBarTile(systemImage: "arrow.triangle.2.circlepath") {
                Text(status)
                    .lineLimit(1)
            }
            .help(ActivityStatusPluginLocalization.string("Current activity"))
        }
    }
}
