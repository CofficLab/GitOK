# GitOK Lumi Architecture Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make GitOK use the same composition-root shape as Lumi: a shared kernel assembled by KernelFactory, with ProviderFactory, PluginFactory, and ViewFactory boundaries, while preserving GitOK's Git domain services and plugin behavior.

**Architecture:** Extract the generic provider registry and lifecycle into KernelCore. Keep GitOK-specific contracts and services in KitGitOKCore/GitOKAppCore, expose them through typed Provider protocols, and let FactoryCore assemble the kernel through explicit factories. The app entry point owns one assembled kernel and passes it to the main/settings views and commands; no production UI or command code resolves RootContainer.shared.

**Tech Stack:** Swift 6, Swift Package Manager, SwiftUI, SwiftData, macOS 14+, Xcode project local package references.

---

### Task 1: Add KernelCore package

**Files:**
- Create: `Packages/KernelCore/Package.swift`
- Create: `Packages/KernelCore/Sources/KernelCore/KernelCore.swift`
- Create: `Packages/KernelCore/Sources/KernelCore/KernelCore+Provider.swift`
- Create: `Packages/KernelCore/Sources/KernelCore/KernelCore+Lifecycle.swift`
- Create: `Packages/KernelCore/Sources/KernelCore/Errors/KernelCoreError.swift`
- Test: `Packages/KernelCore/Tests/KernelCoreTests.swift`

Implement a type-keyed Provider registry and explicit stopped/running lifecycle. Add tests for registration, duplicate rejection, resolution, and unregistering.

### Task 2: Add Lumi-shaped factory contracts

**Files:**
- Modify: `Packages/FactoryCore/Package.swift`
- Create: `Packages/FactoryCore/Sources/FactoryCore/Contracts/PluginFactory.swift`
- Create: `Packages/FactoryCore/Sources/FactoryCore/Contracts/ProviderFactory.swift`
- Create: `Packages/FactoryCore/Sources/FactoryCore/Contracts/ViewFactory.swift`
- Create: `Packages/FactoryCore/Sources/FactoryCore/KernelFactory.swift`

Keep factories independent of concrete plugin packages. KernelFactory owns construction, ProviderFactory owns typed registration, PluginFactory owns the injected catalog, and ViewFactory owns view assembly.

### Task 3: Convert the GitOK host container into a Kernel-backed composition

**Files:**
- Modify: `Packages/FactoryCore/Sources/FactoryCore/Bootstrap/RootContainer.swift`
- Modify: `Packages/KitGitOKCore/Sources/KitGitOKCore/Providers/GitOKPluginDependencies.swift`
- Modify: `Packages/FactoryCore/Sources/FactoryCore/Services/PluginService.swift`

Register GitOK's existing project, Git, theme, navigation, and plugin services into KernelCore. Preserve the old dependency resolver as a compatibility bridge for existing plugins, but make KernelCore the composition source of truth.

### Task 4: Move composition into explicit factories

**Files:**
- Modify: `Packages/FactoryGitOK/Sources/GitOKFactory.swift`
- Modify: `Packages/FactoryGitOK/Sources/GeneratedPluginRegistry.swift`
- Modify: `Packages/FactoryGitOK/Package.swift`
- Modify: `Packages/FactoryCore/Sources/FactoryCore/Views/Layout/ContentLayout.swift`
- Modify: `Packages/FactoryCore/Sources/FactoryCore/Bootstrap/SettingsSceneContent.swift`

Make the registry expose a PluginFactory implementation and make the facade delegate to KernelFactory/ViewFactory. The resulting dependency direction must remain: host packages do not import concrete plugins; only the registry composition package does.

### Task 5: Remove RootContainer.shared from production paths

**Files:**
- Modify: `GitOKApp/GitOKApp.swift`
- Modify: `Packages/FactoryCore/Sources/FactoryCore/Bootstrap/RootView.swift`
- Modify: `Packages/FactoryCore/Sources/FactoryCore/Bootstrap/SettingsWindowOpener.swift`
- Modify: `Packages/FactoryCore/Sources/FactoryCore/Commands/ConfigCommand.swift`
- Modify: `Packages/FactoryCore/Sources/FactoryCore/Commands/GitCommand.swift`

Assemble once in App.init, cache main/settings views, pass the shared kernel to views/commands, and preserve external-file/open-project behavior and settings deep links.

### Task 6: Update architecture checks and documentation

**Files:**
- Modify: `docs/architecture/gitok-app-shell.md`
- Modify: `docs/plugins/architecture.md`
- Modify: `Scripts/check-plugin-package-boundaries.sh`
- Test: `Packages/FactoryGitOK/Tests/GeneratedPluginRegistryTests.swift`

Document the actual Lumi-shaped flow and add checks that forbid RootContainer.shared in App/command/view production code and require explicit registry composition.

### Task 7: Verify

Run:
- `swift test --package-path Packages/KernelCore`
- `swift test --package-path Packages/KitGitOKCore`
- `swift test --package-path Packages/FactoryCore`
- `swift test --package-path Packages/FactoryGitOK`
- `bash Scripts/check-plugin-package-boundaries.sh`
- `xcodebuild -project GitOK.xcodeproj -scheme GitOK -configuration Debug -sdk macosx build`

Expected: all tests/build pass; only pre-existing warnings remain.
