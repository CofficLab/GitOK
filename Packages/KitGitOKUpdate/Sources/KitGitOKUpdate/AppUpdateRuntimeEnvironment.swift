import Foundation

enum AppUpdateRuntimeEnvironment {
    static var allowsAppUpdates: Bool {
        if let value = Bundle.main.object(forInfoDictionaryKey: "GitOKAllowsAppUpdates") as? Bool {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "GitOKAllowsAppUpdates") as? String {
            switch value.lowercased() {
            case "yes", "true", "1": return true
            case "no", "false", "0": return false
            default: break
            }
        }

        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}
