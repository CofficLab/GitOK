import Foundation

class AppHelper {
    func isInSandbox() -> Bool {
        let fileManager = FileManager.default
        let appURLs = fileManager.urls(for: .applicationDirectory, in: .userDomainMask)

        if let appURL = appURLs.first {
            // 判断应用程序的路径是否包含特定的沙盒路径
            return appURL.path.contains("Containers/Data/Application")
        }

        return false
    }
}
