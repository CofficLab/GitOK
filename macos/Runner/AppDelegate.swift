import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // 用于存储上一次Command键按下的时间
  private var lastCommandKeyPressTime: Date?
  // 用于跟踪Command键的状态
  private var isCommandKeyDown = false
  // 全局事件监听器
  private var eventMonitor: Any?
  
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
      // window.hasShadow = true
      // window.isOpaque = false
      // window.backgroundColor = .clear
      
      // 激活应用但不改变当前焦点窗口
      NSApp.activate(ignoringOtherApps: true)
      window.makeKeyAndOrderFront(nil)
    }
    
    // 设置全局事件监听器
    setupGlobalEventMonitor()
    
    super.applicationDidFinishLaunching(notification)
  }
  
  // 设置全局事件监听器
  private func setupGlobalEventMonitor() {
    // 移除现有的监听器（如果有）
    if let existingMonitor = eventMonitor {
      NSEvent.removeMonitor(existingMonitor)
    }
    
    // 创建全局监听器（监听发送到其他应用的事件）
    let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
      self?.handleCommandKeyEvent(event)
    }
    
    // 创建本地监听器（监听发送到自己应用的事件）
    let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
      self?.handleCommandKeyEvent(event)
      return event
    }
    
    // 保存监听器引用
    eventMonitor = [globalMonitor, localMonitor]
  }
  
  // 处理Command键事件
  private func handleCommandKeyEvent(_ event: NSEvent) {
    // 检查Command键的状态
    let commandKeyDown = event.modifierFlags.contains(.command)
    
    // 检测Command键的状态变化
    if commandKeyDown && !isCommandKeyDown {
      // Command键被按下
      let now = Date()
      
      // 检查是否是双击（1秒内）
      if let lastPress = lastCommandKeyPressTime,
         now.timeIntervalSince(lastPress) <= 1.0 {
        // 检测到双击Command键
        print("检测到双击Command键，时间差: \(now.timeIntervalSince(lastPress))秒")
        
        // 检查应用是否在前台
        if isAppActive() {
          // 如果应用在前台，则隐藏应用
          print("应用当前在前台，将隐藏应用")
          hideApp()
        } else {
          // 如果应用在后台，则将应用带到前台
          print("应用当前在后台，将应用带到前台")
          bringAppToFront()
        }
        
        // 重置时间
        lastCommandKeyPressTime = nil
      } else {
        // 记录第一次按下的时间
        lastCommandKeyPressTime = now
        print("Command键被按下，等待第二次点击...")
      }
    } else if !commandKeyDown && isCommandKeyDown {
      // Command键被释放
      print("Command键被释放")
    }
    
    // 更新Command键状态
    isCommandKeyDown = commandKeyDown
  }
  
  // 检查应用是否在前台激活状态
  private func isAppActive() -> Bool {
    return NSApp.isActive
  }
  
  // 隐藏应用
  private func hideApp() {
    DispatchQueue.main.async {
      print("正在隐藏应用...")
      NSApp.hide(nil)
      print("应用已隐藏")
    }
  }
  
  // 将应用带到前台
  private func bringAppToFront() {
    DispatchQueue.main.async {
      print("正在将应用带到前台...")
      NSApp.activate(ignoringOtherApps: true)
      if let window = NSApplication.shared.windows.first {
        window.makeKeyAndOrderFront(nil)
        print("应用已成功带到前台")
      } else {
        print("找不到应用窗口")
      }
    }
  }
  
  // 应用终止时清理资源
  override func applicationWillTerminate(_ notification: Notification) {
    // 移除事件监听器
    if let monitors = eventMonitor as? [Any] {
      for monitor in monitors {
        NSEvent.removeMonitor(monitor)
      }
    }
    
    eventMonitor = nil
    
    super.applicationWillTerminate(notification)
  }
}