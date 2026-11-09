# 插件国际化（i18n）规范

> 本规范定义 GitOK 项目中插件与应用界面的多语言实现方式与静态校验规则。

---

## 1. 资源文件位置

每个需要本地化文案的 package 使用 **String Catalog**（`.xcstrings`）：

```
Packages/<PackageName>/Resources/Localizable.xcstrings
```

- 文件名固定为 `Localizable.xcstrings`，表名（table）保持默认的 `Localizable`；
  不要自行改成 `<PluginName>.xcstrings`，也不要在调用处传入自定义 `table:`。
- 在 `Package.swift` 中用 `.process("Resources")` 声明资源。不要为空 catalog
  保留资源声明：没有文案的 package 不应创建 catalog。
- 应用级文案位于 `GitOKApp/Resources/Localizable.xcstrings`。

## 2. 语言集合

catalog 的 `sourceLanguage` 固定为 `en`，key 直接使用英文原文。每个 key 必须
同时具备以下五种语言的非空翻译：

| 语言 | 说明 |
| --- | --- |
| `en` | 源语言 |
| `zh-Hans` | 简体中文 |
| `zh-Hant` | 繁体中文（通用） |
| `zh-HK` | 繁体中文（香港） |
| `zh-TW` | 繁体中文（台湾） |

应用内的语言切换与系统语言回退由 `KitGitOKLocalization` 统一处理，catalog
条目不参与硬编码语言白名单。

## 3. 调用方式

### 插件 package

```swift
Text(pluginLocalization.string("Commit"))
```

`pluginLocalization` 绑定 `Bundle.module`，未命中时回退为 key 原文。package
若已有自己的 `enum <Name>Localization` 包装（如 `GitDiffLocalization`），优先使用它。

### 应用 target

```swift
Text(GitOKAppLocalization.string("Settings"))
```

### 禁止的写法

- **禁止**把裸字符串直接传给 SwiftUI 文本类初始化器：
  `Text("Commit")`、`Button("Save")`、`Label("Name", ...)`、`Toggle("...")`、
  `TextField("...")`、`SecureField("...")`。
  裸字面量按 `Bundle.main` 解析，插件包内的翻译位于 `Bundle.module`，永远取不到。
- **禁止**在插件里使用 `String(localized:table:)` 或 `NSLocalizedString` 直接查表。
- 纯符号、文件名等不参与翻译的内容使用显式非本地化写法：
  `Text(verbatim: "·")`、`Text(verbatim: "LICENSE")`。

## 4. 格式化字符串

带占位符的文案使用标准格式说明符（`%@`、`%lld`、`%1$@` 等），key 与翻译保持
相同的占位符顺序：

```swift
Text(String(format: pluginLocalization.string("Deleted %lld files"), count))
```

少数格式串只在运行时拼接、源码中没有字面量调用点（例如 `%lld` 本身）。这类
key 允许保留，但必须在 catalog 条目上加 `comment`，且包含
`Runtime-assembled` 标记，说明它由运行时组装：

```json
"stash@{%lld}" : {
  "comment" : "Runtime-assembled format string: referenced through format APIs rather than a literal call site; keep in sync with code.",
  ...
}
```

## 5. 静态校验

校验脚本：`Scripts/check_localization.py`
CI：`.github/workflows/localization.yaml`（PR 及 `dev` / `pre` / `main` 推送时运行）

本地执行：

```bash
python3 Scripts/check_localization.py
```

脚本检查以下内容，任一失败即非零退出：

1. 每个 `Packages/<Package>/Resources/Localizable.xcstrings`（及历史遗留的
   `Sources/Localizable.xcstrings`）是合法 JSON，`sourceLanguage == "en"`，
   且 catalog 非空。
2. 每个 key 非空、未标记 `extractionState: "stale"`，并且五种语言的
   `stringUnit.value` 都非空。
3. 每个 key 都能在 `Packages/<Package>/Sources` 或 `GitOKApp` 的 Swift 源码中
   找到字面量引用；找不到时，必须含 `%` 且带 `Runtime-assembled` 注释。
4. `Packages/*/Sources` 与 `GitOKApp` 中不得出现传给 `Text` / `Label` /
   `Button` / `Toggle` / `TextField` / `SecureField` 的裸字符串字面量
   （`Text(verbatim:)` 不计入）。

## 6. 新增文案流程

1. 在所属 package 的 `Localizable.xcstrings` 中添加 key（英文原文）。
2. 补全 `en` / `zh-Hans` / `zh-Hant` / `zh-HK` / `zh-TW` 五种翻译。
3. 用 `pluginLocalization.string(...)` 或对应包装替换界面字面量。
4. 运行 `python3 Scripts/check_localization.py`，确认无新增问题。
