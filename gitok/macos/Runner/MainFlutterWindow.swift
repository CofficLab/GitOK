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
    
    // 设置面板样式 - 确保包含了正确的标志
    self.styleMask = [.nonactivatingPanel, .titled, .resizable, .fullSizeContentView]
    self.isFloatingPanel = true
    self.level = .modalPanel
    
    // 设置窗口视觉效果
    self.backgroundColor = .clear
    self.isOpaque = false
    self.hasShadow = true
    
    // 添加毛玻璃效果
    if let visualEffect = self.contentView as? NSVisualEffectView {
      visualEffect.material = .hudWindow  // 使用 HUD 风格材质
      visualEffect.blendingMode = .behindWindow
      visualEffect.state = .active
    } else {
      let visualEffect = NSVisualEffectView(frame: self.contentView?.bounds ?? .zero)
      visualEffect.material = .hudWindow
      visualEffect.blendingMode = .behindWindow
      visualEffect.state = .active
      self.contentView?.addSubview(visualEffect, positioned: .below, relativeTo: nil)
      visualEffect.autoresizingMask = [.width, .height]
    }
    
    // 确保这些设置正确
    self.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
    self.isMovableByWindowBackground = true

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
