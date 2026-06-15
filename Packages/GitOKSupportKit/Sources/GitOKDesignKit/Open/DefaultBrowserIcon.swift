#if os(macOS)
import AppKit
import CoreServices

enum DefaultBrowserIcon {
    static func nsImage() -> NSImage? {
        guard let bundleID = LSCopyDefaultHandlerForURLScheme("https" as CFString)?.takeRetainedValue() as String?,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
#endif
