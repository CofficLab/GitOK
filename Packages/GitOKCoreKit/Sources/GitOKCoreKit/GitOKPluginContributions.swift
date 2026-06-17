import SwiftUI

public struct GitOKTabItem: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let order: Int

    public init(id: String, name: String, order: Int) {
        self.id = id
        self.name = name
        self.order = order
    }
}

public struct GitOKToolbarItem: Identifiable {
    public let id: String
    public let view: AnyView

    public init(id: String, view: AnyView) {
        self.id = id
        self.view = view
    }
}

public typealias GitOKListPaneItem = GitOKPluginViewContribution
public typealias DetailPane = GitOKPluginViewContribution

public struct GitOKRailItem: Identifiable {
    public let id: String
    public let iconName: String
    public let title: String
    public let order: Int
    public let view: AnyView

    public init(
        id: String,
        iconName: String,
        title: String,
        order: Int = 9999,
        view: AnyView
    ) {
        self.id = id
        self.iconName = iconName
        self.title = title
        self.order = order
        self.view = view
    }
}

public struct GitOKStatusBarItem: Identifiable {
    public let id: String
    public let view: AnyView

    public init(id: String, view: AnyView) {
        self.id = id
        self.view = view
    }
}

public struct GitOKRootOverlayItem: Identifiable {
    public let id: String
    public let view: AnyView

    public init(id: String, view: AnyView) {
        self.id = id
        self.view = view
    }
}

public enum GitOKOnboardingKind: String, Sendable {
    case emptyProjects
    case projectNotFound
    case missingDetail
}

public struct GitOKOnboardingPaneItem: Identifiable {
    public let id: String
    public let kind: GitOKOnboardingKind
    public let view: AnyView

    public init(id: String, kind: GitOKOnboardingKind, view: AnyView) {
        self.id = id
        self.kind = kind
        self.view = view
    }
}

public struct GitOKSettingsPaneItem: Identifiable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let order: Int
    public let view: AnyView

    public init(
        id: String,
        title: String,
        systemImage: String = "gearshape",
        order: Int = 9999,
        view: AnyView
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.order = order
        self.view = view
    }
}

/// App-layer services resolved through plugin context.
