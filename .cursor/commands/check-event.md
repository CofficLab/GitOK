# 事件监听扩展检查指令

## 重要规则

仅执行指令，无需进行总结。

## 步骤

1. 按照 [Swift 文件事件监听扩展规则](.cursor/rules/swift-event-rule.mdc) 的要求检查文档，修复不规范的地方

## 检查要点

### 1. 事件抛出检查
检查文件中抛出的事件是否符合规范：
- 使用 `NotificationCenter.default.post(name: .customEvent, object: self)` 发送通知
- 或使用 `PassthroughSubject<Void, Never>()` 等 Combine Publisher
- 确保事件命名清晰、有意义

### 2. View 扩展要求
对于每个抛出的事件，必须检查是否存在对应的 View 扩展方法：
```swift
extension View {
    func onCustomEvent(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .customEvent)) { _ in
            action()
        }
    }
}
```

### 3. 方法命名规范
- **必须以 `on` 开头**：`onEventName`
- **驼峰命名法**：`onApplicationDidBecomeActive`
- **语义清晰**：方法名应准确反映监听的事件类型
- **参数规范**：使用 `perform action: @escaping () -> Void`

### 4. 实现规范
#### NotificationCenter 事件
```swift
extension View {
    func onEventName(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .eventName)) { _ in
            action()
        }
    }
}
```

#### Combine Publisher 事件
```swift
extension View {
    func onEventName(_ publisher: some Publisher<Void, Never>, perform action: @escaping () -> Void) -> some View {
        self.onReceive(publisher) { _ in
            action()
        }
    }
}
```

### 5. 扩展位置
- View 扩展应放在抛出事件的同一个文件中
- 或放在相关工具文件中
- 确保扩展方法在项目中可访问

### 6. 使用验证
检查 View 文件中是否正确使用了这些扩展方法：
```swift
struct MyView: View {
    var body: some View {
        Text("Hello")
            .onApplicationDidBecomeActive {
                print("App became active!")
            }
            .onCustomEvent {
                print("Custom event received!")
            }
    }
}
```

### 7. 线程安全
- 确保事件处理在正确的线程执行
- UI 更新操作应在主线程执行
- 注意避免循环引用，特别是使用 Combine Publisher 时

### 8. 命名冲突检查
- 确保 `onXxx` 方法名在项目中唯一
- 避免与系统或其他库的方法名冲突
- 如有冲突，使用更具体的命名空间前缀
