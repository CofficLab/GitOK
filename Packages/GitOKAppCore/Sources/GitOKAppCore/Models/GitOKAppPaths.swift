import Foundation

public enum GitOKAppPaths {
    public static func getAppName() -> String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "GitOK"
    }

    public static func getCurrentAppSupportDir() -> URL {
        let base = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent(getAppName())
    }
}
