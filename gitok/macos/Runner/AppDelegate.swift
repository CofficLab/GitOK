import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = NSApplication.shared.windows.first {
      window.level = .popUpMenu
      window.styleMask = [.nonactivatingPanel]
      window.collectionBehavior = [.moveToActiveSpace]
      window.hasShadow = true
      window.isOpaque = false
      window.backgroundColor = .clear
      
      // 激活应用但不改变当前焦点窗口
      NSApp.activate(ignoringOtherApps: true)
      window.makeKeyAndOrderFront(nil)
    }
    super.applicationDidFinishLaunching(notification)
  }
}