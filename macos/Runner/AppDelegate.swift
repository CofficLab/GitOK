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
  // Flutter方法通道
  private var methodChannel: FlutterMethodChannel?
  // 日志方法通道
  private var logChannel: FlutterMethodChannel?
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // 设置Flutter方法通道
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      // 设置主方法通道
      methodChannel = FlutterMethodChannel(
        name: "com.cofficlab.gitok/window",
        binaryMessenger: controller.engine.binaryMessenger)
      
      // 设置日志方法通道
      logChannel = FlutterMethodChannel(
        name: "com.cofficlab.gitok/logger",
        binaryMessenger: controller.engine.binaryMessenger)
      
      log("✅ 方法通道设置完成")
    } else {
      log("❌ 无法设置方法通道：找不到 FlutterViewController", level: "error")
    }
    
    if let window = NSApplication.shared.windows.first {
      window.level = .popUpMenu
      window.styleMask = [.nonactivatingPanel]
      window.collectionBehavior = [.moveToActiveSpace]
      
      // 激活应用但不改变当前焦点窗口
      NSApp.activate(ignoringOtherApps: true)
      window.makeKeyAndOrderFront(nil)
      log("✅ 窗口设置完成")
    } else {
      log("❌ 找不到主窗口", level: "error")
    }
    
    // 设置全局事件监听器
    setupGlobalEventMonitor()
    
    super.applicationDidFinishLaunching(notification)
  }
  
  // 统一的日志方法
  private func log(_ message: String, level: String = "info", tag: String = "AppDelegate") {
    // 首先通过日志通道发送到Flutter
    logChannel?.invokeMethod("log", arguments: [
      "message": message,
      "level": level,
      "tag": tag
    ])
    
    // 同时保持原有的NSLog输出，以防日志通道未准备好
    NSLog("[\(tag)] \(message)")
  }
  
  // 设置全局事件监听器
  private func setupGlobalEventMonitor() {
    log("🎯 开始设置事件监听器...")
    
    // 移除现有的监听器（如果有）
    if let existingMonitor = eventMonitor {
      NSEvent.removeMonitor(existingMonitor)
      log("🗑️ 移除旧的事件监听器")
    }
    
    // 创建全局监听器（监听发送到其他应用的事件）
    let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
      self?.log("收到全局事件", tag: "EventMonitor")
      self?.handleCommandKeyEvent(event)
    }
    
    // 创建本地监听器（监听发送到自己应用的事件）
    let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
      self?.log("收到本地事件", tag: "EventMonitor")
      self?.handleCommandKeyEvent(event)
      return event
    }
    
    // 保存监听器引用
    eventMonitor = [globalMonitor, localMonitor]
    log("✅ 事件监听器设置完成")
  }
  
  // 处理Command键事件
  private func handleCommandKeyEvent(_ event: NSEvent) {
    log("处理Command键事件...", tag: "KeyHandler")
    
    // 检查Command键的状态
    let commandKeyDown = event.modifierFlags.contains(.command)
    log("Command键状态: \(commandKeyDown ? "按下" : "释放")", tag: "KeyHandler")
    
    // 检测Command键的状态变化
    if commandKeyDown && !isCommandKeyDown {
      // Command键被按下
      let now = Date()
      log("Command键被按下", tag: "KeyHandler")
      
      // 检查是否是双击（1秒内）
      if let lastPress = lastCommandKeyPressTime,
         now.timeIntervalSince(lastPress) <= 1.0 {
        // 检测到双击Command键
        log("检测到双击Command键!", tag: "KeyHandler")
        log("两次点击时间间隔: \(now.timeIntervalSince(lastPress))秒", tag: "KeyHandler")
        
        // 检查应用是否在前台
        if isAppActive() {
          // 如果应用在前台，则隐藏应用
          log("应用当前在前台，准备隐藏", tag: "AppState")
          hideApp()
        } else {
          // 如果应用在后台，则将应用带到前台
          log("应用当前在后台，准备显示", tag: "AppState")
          bringAppToFront()
        }
        
        // 重置时间
        lastCommandKeyPressTime = nil
        log("重置双击计时器", tag: "KeyHandler")
      } else {
        // 记录第一次按下的时间
        lastCommandKeyPressTime = now
        log("记录第一次Command键点击，等待第二次点击...", tag: "KeyHandler")
      }
    } else if !commandKeyDown && isCommandKeyDown {
      // Command键被释放
      log("Command键被释放", tag: "KeyHandler")
    }
    
    // 更新Command键状态
    isCommandKeyDown = commandKeyDown
    log("更新Command键状态: \(commandKeyDown ? "按下" : "释放")", tag: "KeyHandler")
  }
  
  // 检查应用是否在前台激活状态
  private func isAppActive() -> Bool {
    let active = NSApp.isActive
    log("检查应用状态: \(active ? "活跃" : "非活跃")", tag: "AppState")
    return active
  }
  
  // 隐藏应用
  private func hideApp() {
    log("准备隐藏应用...", tag: "AppState")
    DispatchQueue.main.async { [weak self] in
      self?.log("正在隐藏应用...", tag: "AppState")
      // 清除被覆盖的应用信息
      self?.methodChannel?.invokeMethod("updateOverlaidApp", arguments: nil)
      NSApp.hide(nil)
      self?.log("应用已隐藏", tag: "AppState")
    }
  }
  
  // 将应用带到前台
  private func bringAppToFront() {
    log("准备将应用带到前台...", tag: "AppState")
    DispatchQueue.main.async { [weak self] in
      self?.log("正在获取当前活跃应用信息...", tag: "AppState")
      
      // 先获取当前活跃的应用信息
      if let activeApp = NSWorkspace.shared.frontmostApplication {
        self?.log("成功获取当前活跃应用:", tag: "AppState")
        self?.log("我们将覆盖在此应用之上:", tag: "AppState")
        self?.log("""
          应用名称: \(activeApp.localizedName ?? "未知")
          Bundle ID: \(activeApp.bundleIdentifier ?? "未知")
          进程 ID: \(activeApp.processIdentifier)
        """, tag: "AppState")
        
        // 保存当前活跃应用的信息
        let overlaidApp = [
          "name": activeApp.localizedName ?? "未知",
          "bundleId": activeApp.bundleIdentifier ?? "未知",
          "processId": activeApp.processIdentifier
        ]
        
        // 然后再将我们的应用带到前台
        self?.log("正在激活我们的应用...", tag: "AppState")
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
          window.makeKeyAndOrderFront(nil)
          self?.log("应用已成功带到前台", tag: "AppState")
          
          // 发送之前保存的被覆盖应用信息
          self?.methodChannel?.invokeMethod("updateOverlaidApp", arguments: overlaidApp)
        } else {
          self?.log("找不到应用窗口", level: "error", tag: "AppState")
        }
      } else {
        self?.log("无法获取当前活跃应用", level: "error", tag: "AppState")
        // 清除被覆盖的应用信息
        self?.methodChannel?.invokeMethod("updateOverlaidApp", arguments: nil)
        
        // 仍然需要激活我们的应用
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
          window.makeKeyAndOrderFront(nil)
          self?.log("应用已成功带到前台", tag: "AppState")
        }
      }
    }
  }
  
  // 应用终止时清理资源
  override func applicationWillTerminate(_ notification: Notification) {
    log("应用即将终止...", tag: "AppLifecycle")
    // 移除事件监听器
    if let monitors = eventMonitor as? [Any] {
      for monitor in monitors {
        NSEvent.removeMonitor(monitor)
      }
    }
    
    eventMonitor = nil
    log("清理完成", tag: "AppLifecycle")
    
    super.applicationWillTerminate(notification)
  }
}