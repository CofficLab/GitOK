import Foundation
import SwiftUI

/// Supplies a rendered README view for a project directory.
@MainActor
public protocol ProjectReadmeProviding: AnyObject {
    func makeReadmeView(for projectURL: URL) -> AnyView
}
