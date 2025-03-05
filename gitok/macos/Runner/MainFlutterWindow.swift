import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 设置面板样式
    self.styleMask = [.nonactivatingPanel, .titled, .resizable]
    self.isFloatingPanel = true  // 设置为浮动面板
    self.level = .modalPanel  // 使用更高的窗口层级
    self.collectionBehavior = [.fullScreenAuxiliary, .stationary]
    self.isMovableByWindowBackground = true
    self.backgroundColor = .clear

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
