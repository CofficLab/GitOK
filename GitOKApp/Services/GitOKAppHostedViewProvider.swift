import GitOKCoreKit
import SwiftUI

@MainActor
final class GitOKAppHostedViewProvider: GitOKAppHostedViewProviding {
    func gitDetailView(context: GitOKPluginContext) -> AnyView? {
        AnyView(GitDetail())
    }
}
