# FactoryGitOK

GitOK 应用的装配根（composition root）：`KernelFactory` 组装内核、Provider 与插件目录，`PluginFactory` / `ProviderFactory` / `ViewFactory` 构建主界面、设置界面与应用命令。

## 本 Package 的位置

| 属性 | 值 |
|------|-----|
| **类型** | 应用装配根（Composition Root） |
| **宿主** | GitOK 应用（`GitOKApp`） |
| **上游依赖** | `KernelCore`、`KitGit`、`KitLocalization`、`PluginAboutSettings`、`PluginActivityStatus`、`PluginCloneRepository`、`PluginCommand`、`PluginCommitDetail`、`PluginCommitForm`、`PluginCommitList`、`PluginCommitStatusBar`、`PluginCommitToast`、`PluginDiagnosticsSettings`、`PluginFileInfo`、`PluginGitAutoPush`、`PluginGitBranchStatus`、`PluginGitCommitStyleSettings`、`PluginGitConflictResolver`、`PluginGitDiff`、`PluginGitIgnore`、`PluginGitLFS`、`PluginGitNetworkSettings`、`PluginGitRemoteRepository`、`PluginGitRepositorySettings`、`PluginGitRepositoryWatch`、`PluginGitSmartMerge`、`PluginGitStash`、`PluginGitSubmodule`、`PluginGitUnpushedStatus`、`PluginGitUserSettings`、`PluginLicense`、`PluginLogoCoffic`、`PluginLogoManager`、`PluginOpenAntigravity`、`PluginOpenCursor`、`PluginOpenFinder`、`PluginOpenGitHubDesktop`、`PluginOpenKiro`、`PluginOpenLumi`、`PluginOpenRemote`、`PluginOpenTerminal`、`PluginOpenTrae`、`PluginOpenVSCode`、`PluginOpenXcode`、`PluginPluginManager`、`PluginProjects`、`PluginRootView`、`PluginSettingGeneral`、`PluginSettingView`、`PluginSettingsButton`、`PluginSidebarToggle`、`PluginStatusBar`、`PluginStorage`、`PluginThemePack`、`PluginToast`、`PluginWorktreeClean`、`PluginWorktreeStatus`、`ProviderActivity`、`ProviderAutoPush`、`ProviderCloneRepository`、`ProviderCommand`、`ProviderCommitForm`、`ProviderContentView`、`ProviderDocsView`、`ProviderLogo`、`ProviderPluginControl`、`ProviderPluginManaging`、`ProviderProjects`、`ProviderRailView`、`ProviderRootView`、`ProviderSettingView`、`ProviderSidebar`、`ProviderStatusBar`、`ProviderStorage`、`ProviderTheme`、`ProviderToast`、`ProviderToolbar`；https://github.com/CofficLab/LumiUI.git |
| **平台** | macOS 14+ |

## 目录结构

```text
└── FactoryGitOK
    ├── Resources
    │   └── Localizable.xcstrings
    ├── Sources
    │   └── FactoryGitOK
    │       ├── AppCommands.swift
    │       ├── Contracts
    │       │   ├── SuperPluginFactory.swift
    │       │   ├── SuperProviderFactory.swift
    │       │   └── SuperViewFactory.swift
    │       ├── FactoryGitOK.swift
    │       ├── KernelFactory.swift
    │       ├── PaletteChromeTheme.swift
    │       ├── PluginFactory.swift
    │       ├── ProviderFactory.swift
    │       ├── Support
    │       │   └── LumiPluginLocalization.swift
    │       └── ViewFactory.swift
    └── Tests
        └── FactoryGitOKTests
            ├── FactoryGitOKTests.swift
            └── KernelBootIntegrationTests.swift
```

## 构建与测试

```bash
# 构建
swift build

# 测试
swift test
```
