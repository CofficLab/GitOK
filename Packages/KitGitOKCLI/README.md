# KitGitOKCLI

`gitok` 命令行工具的安装与状态管理。

## 职责

| 类型 | 职责 |
|---|---|
| `CLIScriptBuilder` | 生成 `gitok` shell 脚本内容 |
| `CLIInstallTargetResolver` | 选择安装目录（优先已在 `PATH` 中的可写目录） |
| `CLIInstaller` | 安装 / 卸载 / 查询安装状态 |

## 设计约束

- **不需要管理员权限**：只写入用户可写目录（`PATH` 中的可写目录或 `~/.local/bin`）。
- **不修改用户 shell 配置**：不改 `.zshrc` / `.bash_profile`；若目标目录不在
  `PATH` 中，由 UI 提示用户自行加入。
- **不依赖 App bundle 内的文件**：脚本只通过 `GITOK_APP` 环境变量或默认安装
  位置定位 App，App 移动或升级后依然可用。

## 用法

```swift
let status = CLIInstaller.status()
if !status.isInstalled {
    let outcome = CLIInstaller.install()
    // .installedButNotOnPath 表示需要提示用户把目录加入 PATH
}
```
