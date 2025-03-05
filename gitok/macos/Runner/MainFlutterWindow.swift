import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
  
  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 { // ESC key code
      self.orderOut(nil)  // 使用 orderOut 来隐藏窗口而不是关闭
    } else {
      super.keyDown(with: event)
    }
  }
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 设置面板样式
    self.styleMask = [.nonactivatingPanel, .titled, .resizable]
    self.isFloatingPanel = true
    self.level = .modalPanel
    self.collectionBehavior = [.fullScreenAuxiliary, .stationary]
    self.isMovableByWindowBackground = true
    self.backgroundColor = .clear

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
