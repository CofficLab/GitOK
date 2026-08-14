import SwiftUI

public struct GitOKPluginViewContribution: Identifiable {
    public let id: String
    public let view: AnyView

    public init(id: String, view: AnyView) {
        self.id = id
        self.view = view
    }
}
