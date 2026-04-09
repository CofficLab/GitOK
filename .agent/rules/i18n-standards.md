# Lumi 插件多语言规范

> 基于 Lumi 项目中 60+ 插件的实际代码分析总结，作为 GitOK 项目的多语言参考标准。

---

## 1. 核心架构

### 1.1 使用 Xcode String Catalogs (`.xcstrings`)

Lumi 使用 Xcode 15+ 的 String Catalogs (`.xcstrings`) 文件来管理多语言字符串。这是一个现代化的本地化解决方案，支持：
- JSON 格式
- 自动格式化验证
- Xcode 原生编辑器支持
- 运行时字符串本地化

### 1.2 文件位置

每个插件的多语言文件位于插件根目录：

```
Plugins/
├── MyPlugin/
│   ├── MyPlugin.swift
│   ├── MyPlugin.xcstrings      ← 多语言文件
│   ├── Views/
│   └── ...
```

**命名规则**：`<PluginName>.xcstrings`

### 1.3 支持的语言

| 语言代码 | 名称 | 用途 |
|---------|------|------|
| `en` | English | 源语言 |
| `zh-Hans` | 简体中文 | 主要中文 |
| `zh-HK` | 繁體中文（香港） | 可选 |

---

## 2. .xcstrings 文件格式

### 2.1 文件结构

```json
{
  "sourceLanguage": "en",
  "strings": {
    "key": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "English text"
          }
        },
        "zh-Hans": {
          "stringUnit": {
            "state": "translated",
            "value": "简体中文"
          }
        },
        "zh-HK": {
          "stringUnit": {
            "state": "translated",
            "value": "繁體中文"
          }
        }
      }
    }
  },
  "version": "1.1"
}
```

### 2.2 字段说明

| 字段 | 值 | 说明 |
|------|-----|------|
| `sourceLanguage` | `"en"` | 源语言，固定为英文 |
| `extractionState` | `"manual"` | 提取状态，手动管理 |
| `state` | `"translated"` | 翻译状态 |
| `value` | 文本内容 | 实际显示的字符串 |
| `version` | `"1.1"` | 文件格式版本 |

### 2.3 格式化参数

使用 `%@` 占位符，在代码中传递参数：

**.xcstrings**：
```json
{
  "Installation failed: %@": {
    "localizations": {
      "en": {
        "stringUnit": {
          "value": "Installation failed: %@"
        }
      },
      "zh-Hans": {
        "stringUnit": {
          "value": "安装失败：%@"
        }
      }
    }
  }
}
```

**Swift 代码**：
```swift
String(localized: "Installation failed: %@", table: "BrewManager", error.localizedDescription)
```

---

## 3. 代码中使用多语言

### 3.1 基本用法

```swift
// 插件属性
static let displayName: String = String(localized: "My Plugin", table: "MyPlugin")
static let description: String = String(localized: "Plugin description", table: "MyPlugin")
```

### 3.2 带参数的用法

```swift
let errorMessage = String(localized: "Installation failed: %@", table: "MyPlugin", error.localizedDescription)
```

### 3.3 在 ViewModel 中使用

```swift
class MyViewModel: ObservableObject {
    @Published var errorMessage: String?
    
    func performAction() async {
        do {
            try await someOperation()
        } catch {
            errorMessage = String(localized: "Operation failed: %@", table: "MyPlugin", error.localizedDescription)
        }
    }
}
```

### 3.4 在 View 中使用

```swift
struct MyView: View {
    var body: some View {
        Text("Hello, World!")  // 直接使用字符串字面量（推荐）
            // 或
        Text(String(localized: "Welcome", table: "MyPlugin"))
    }
}
```

---

## 4. 命名规范

### 4.1 Key 命名规则

| 规则 | 示例 | 说明 |
|------|------|------|
| 插件名称 | `My Plugin` | 插件显示名称 |
| 插件描述 | `Plugin description` | 插件描述文本 |
| UI 文本 | `Button Title` | 使用 PascalCase |
| 错误消息 | `Error message` | 描述性文本 |
| 状态消息 | `Processing...` | 可包含标点 |

### 4.2 常见 Key 模式

```swift
// 插件信息
"My Plugin"                    // 插件名称
"Plugin description"           // 插件描述

// UI 元素
"Close"                        // 按钮
"Cancel"                       // 按钮
"Save"                         // 按钮
"Settings"                     // 导航标题

// 状态消息
"Loading..."                   // 加载中
"Processing..."                // 处理中
"Success"                      // 成功

// 错误消息
"Error"                        // 错误标题
"Operation failed: %@"         // 带参数的错误
"Network error: %@"            // 网络错误

// 占位符
"Enter keywords to search"     // 输入框占位符
"Select a project"             // 提示文本
```

---

## 5. 翻译规范

### 5.1 英文翻译（源语言）

- 使用简洁、自然的英文
- 首字母大写（标题大小写）
- 避免缩写（除非是通用缩写如 OK, API）
- 保持一致性

**示例**：
```swift
✅ "Auto Push"           // 推荐
❌ "AutoPush"           // 不推荐
❌ "auto push"          // 不推荐

✅ "Enable auto push"    // 推荐
❌ "Enable AutoPush"    // 不推荐（不要混合大小写）
```

### 5.2 中文翻译

- 使用简体中文
- 使用中文标点（全角）：`：` `、` `。`
- 保持简洁、自然
- 不要在中文中混用英文单词（除非是技术术语）

**示例**：
```swift
✅ "自动推送"             // 推荐
❌ "AutoPush"           // 不推荐（不要直接用英文）
❌ "自动推"              // 不推荐（太简略）

✅ "安装失败：%@"        // 推荐
❌ "安装失败: %@"        // 不推荐（半角冒号）
```

### 5.3 繁体中文（可选）

- 香港繁体：使用香港用词
- 台湾繁体：使用台湾用词

**示例**：
```swift
// 香港（zh-HK）
"軟件" → "軟件"
"服务器" → "伺服器"

// 台湾（zh-TW）
"软件" → "軟體"
"服务器" → "伺服器"
```

---

## 6. 实际示例

### 6.1 插件主体（Plugin）

**MyPlugin.swift**：
```swift
actor MyPlugin: SuperPlugin, SuperLog {
    static let id: String = "MyPlugin"
    static let displayName: String = String(localized: "My Plugin", table: "MyPlugin")
    static let description: String = String(localized: "Plugin description text", table: "MyPlugin")
    static let iconName: String = "star.fill"
}
```

**MyPlugin.xcstrings**：
```json
{
  "sourceLanguage": "en",
  "strings": {
    "My Plugin": {
      "extractionState": "manual",
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "My Plugin" } },
        "zh-Hans": { "stringUnit": { "state": "translated", "value": "我的插件" } },
        "zh-HK": { "stringUnit": { "state": "translated", "value": "我的插件" } }
      }
    },
    "Plugin description text": {
      "extractionState": "manual",
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "Plugin description text" } },
        "zh-Hans": { "stringUnit": { "state": "translated", "value": "插件描述文本" } },
        "zh-HK": { "stringUnit": { "state": "translated", "value": "插件描述文本" } }
      }
    }
  },
  "version": "1.1"
}
```

### 6.2 ViewModel

**MyViewModel.swift**：
```swift
class MyViewModel: ObservableObject, SuperLog {
    @Published var errorMessage: String?
    
    func performAction() async {
        do {
            try await doSomething()
            if Self.verbose {
                MyPlugin.logger.info("\(Self.t)✅ 操作成功")
            }
        } catch {
            // 错误日志始终输出（中文）
            MyPlugin.logger.error("\(Self.t)❌ 操作失败: \(error.localizedDescription)")
            // UI 错误消息使用多语言
            errorMessage = String(localized: "Operation failed: %@", table: "MyPlugin", error.localizedDescription)
        }
    }
}
```

**MyPlugin.xcstrings**（添加）：
```json
{
  "Operation failed: %@": {
    "localizations": {
      "en": { "stringUnit": { "value": "Operation failed: %@" } },
      "zh-Hans": { "stringUnit": { "value": "操作失败：%@" } },
      "zh-HK": { "stringUnit": { "value": "操作失敗：%@" } }
    }
  }
}
```

### 6.3 View

**MyView.swift**：
```swift
struct MyView: View {
    var body: some View {
        VStack {
            Text("Welcome")
                .font(.headline)
            
            Button("Start") {
                // action
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }
}
```

**MyPlugin.xcstrings**（添加）：
```json
{
  "Welcome": {
    "localizations": {
      "en": { "stringUnit": { "value": "Welcome" } },
      "zh-Hans": { "stringUnit": { "value": "欢迎" } },
      "zh-HK": { "stringUnit": { "value": "歡迎" } }
    }
  },
  "Start": {
    "localizations": {
      "en": { "stringUnit": { "value": "Start" } },
      "zh-Hans": { "stringUnit": { "value": "开始" } },
      "zh-HK": { "stringUnit": { "value": "開始" } }
    }
  }
}
```

---

## 7. 日志 vs UI 多语言

| 用途 | 语言 | 使用方式 |
|------|------|---------|
| **日志输出** | 中文 | 直接写中文字符串（不使用 `String(localized:)`） |
| **UI 显示** | 多语言 | 使用 `String(localized:..., table:...)` |
| **错误日志** | 中文 | `logger.error("\(Self.t)❌ 操作失败: \(error.localizedDescription)")` |
| **错误 UI** | 多语言 | `errorMessage = String(localized: "Operation failed: %@", table: "MyPlugin", error.localizedDescription)` |

### 示例对比

```swift
// 日志 - 直接使用中文（方便调试）
if Self.verbose {
    MyPlugin.logger.info("\(Self.t)📦 初始化完成")
}
MyPlugin.logger.error("\(Self.t)❌ 操作失败: \(error.localizedDescription)")

// UI - 使用多语言
static let displayName: String = String(localized: "My Plugin", table: "MyPlugin")
let uiMessage = String(localized: "Operation failed: %@", table: "MyPlugin", error.localizedDescription)
```

---

## 8. 注意事项

1. **日志不使用多语言** — 日志输出使用中文，方便调试和问题排查
2. **UI 必须使用多语言** — 所有用户可见的文本必须支持多语言
3. **key 必须唯一** — 在同一个 `.xcstrings` 文件中，key 不能重复
4. **避免硬编码** — View 中尽量使用 `String(localized:)` 或直接使用字符串字面量（Xcode 会自动提取）
5. **参数使用 `%@`** — 格式化参数统一使用 `%@`，不要使用其他占位符
6. **table 参数指定插件名** — 使用 `table: "PluginName"` 指定对应的 `.xcstrings` 文件名（不含扩展名）
7. **保持一致性** — 相同概念使用相同的翻译
8. **定期检查** - 确保所有新增的 UI 文本都有对应的翻译

---

## 9. 快速参考

### 创建新插件的多语言文件

1. 在插件根目录创建 `MyPlugin.xcstrings` 文件
2. 添加插件名称和描述：
```json
{
  "sourceLanguage": "en",
  "strings": {
    "My Plugin": {
      "extractionState": "manual",
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "My Plugin" } },
        "zh-Hans": { "stringUnit": { "state": "translated", "value": "我的插件" } }
      }
    },
    "Plugin description": {
      "extractionState": "manual",
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "Plugin description" } },
        "zh-Hans": { "stringUnit": { "state": "translated", "value": "插件描述" } }
      }
    }
  },
  "version": "1.1"
}
```

3. 在代码中使用：
```swift
static let displayName: String = String(localized: "My Plugin", table: "MyPlugin")
static let description: String = String(localized: "Plugin description", table: "MyPlugin")
```