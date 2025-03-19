import Cocoa
import FlutterMacOS
import window_manager

/// 主窗口类
///
/// 这是应用程序的主窗口实现，继承自 NSPanel。
/// 主要功能：
/// 1. 支持窗口拖动：
///    - 通过 .titled 样式标志启用窗口拖动功能
///    - 配合 Flutter 层的 DragToMoveArea 组件使用
///    - 注意：仅设置 .titled 不够，还需要在 Flutter 层添加可拖动区域
/// 2. 支持窗口按键：
///    - ESC 键隐藏窗口
/// 3. 窗口样式：
///    - 使用原生 NSVisualEffectView 实现毛玻璃效果
///    - 支持调整大小
///    - 保持在其他窗口之上
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
    self.styleMask = [.nonactivatingPanel, .resizable, .fullSizeContentView, .titled]
    self.isFloatingPanel = true
    self.level = .modalPanel
    
    // 设置窗口基本属性
    self.backgroundColor = .clear
    self.isOpaque = false
    self.hasShadow = true
    
    // 创建并配置毛玻璃效果视图
    let visualEffectView = NSVisualEffectView()
    visualEffectView.frame = self.contentView?.bounds ?? .zero
    visualEffectView.autoresizingMask = [.width, .height]
    visualEffectView.material = .hudWindow
    visualEffectView.blendingMode = .behindWindow
    visualEffectView.state = .active
    visualEffectView.wantsLayer = true
    
    // 将毛玻璃效果视图插入到视图层级中
    if let contentView = self.contentView {
        contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
    }
    
    // 确保这些设置正确
    self.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
    self.isMovableByWindowBackground = true

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
