import Foundation

@MainActor
public enum GitOKAppNavigationBridge {
    public static var openSettings: (() -> Void)?
    public static var openPluginSettings: (() -> Void)?
}
