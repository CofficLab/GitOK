# ProviderGitUser

Git 用户预设能力包：定义用户身份预设模型、Provider 契约和默认 JSON 持久化实现。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 能力协议包（Provider 层） |
| **宿主** | 由宿主插件通过 KernelCore 装配 |
| **上游依赖** | Foundation |
| **平台** | macOS 14+ |

该包不依赖完整的 `ProviderGit`，因此设置、工作区和提交相关插件可以共享
用户预设能力，而不会耦合到 Git 操作后端。

## 构建与测试

```bash
swift build
swift test
```
