import GitOKCoreKit
import SwiftUI

public struct ActivityStatusTile: View {
    private let activityStatus: String?

    public init(activityStatus: String? = nil) {
        self.activityStatus = activityStatus
    }

    public var body: some View {
        if let status = activityStatus, status.isEmpty == false {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, weight: .semibold))
                Text(status)
                    .font(.footnote)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .contentShape(Rectangle())
            .help(ActivityStatusPluginLocalization.string("Current activity"))
        }
    }
}
