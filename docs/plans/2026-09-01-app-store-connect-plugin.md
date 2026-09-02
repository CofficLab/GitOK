# App Store Connect Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore the App Store Connect management plugin as a current `KernelCore` plugin with its historical UI and Agent tool capabilities.

**Architecture:** Create `Packages/PluginAppStoreConnect` with the current `SuperPlugin` lifecycle, `ProviderActivityBar`/`ProviderRailView`/`ProviderContentView`/`ProviderChatSection`/`ProviderRootView` contributions, `ProviderToolManager` Agent tool registration, `ProviderNetwork` HTTP access, and `ProviderStorage`/Keychain-backed persistence. Preserve the stable plugin id `com.coffic.lumi.plugin.app-store-connect`, rail id, API payloads, caches, and localizations while removing all `KernelLumi`/`LumiPlugin` dependencies. Register the package in `FactoryLumi` using the current package/product naming pattern.

**Tech Stack:** Swift 6, SwiftUI, KernelCore, KitAgentTool, KitLocalization, KitSuperLog, LumiUI, ProviderNetwork, ProviderStorage, ProviderToolManager, Security framework, Swift Testing.

---

### Task 1: Establish the package skeleton and current dependency graph

**Files:**
- Create: `Packages/PluginAppStoreConnect/Package.swift`
- Create: `Packages/PluginAppStoreConnect/README.md`
- Create: `Packages/PluginAppStoreConnect/.gitignore`
- Create: `Packages/PluginAppStoreConnect/Resources/Localizable.xcstrings`

**Step 1: Write the package manifest**

Use package name/product/module `PluginAppStoreConnect`, with the implementation target named `PluginAppStoreConnect`. Depend only on current packages: `KernelCore`, `KitAgentTool`, `KitLocalization`, `KitSuperLog`, `LumiUI`, `ProviderActivityBar`, `ProviderChatSection`, `ProviderContentView`, `ProviderDocsView`, `ProviderNetwork`, `ProviderRailView`, `ProviderRootView`, `ProviderStorage`, `ProviderToolbar`, and `ProviderToolManager`. Link `Security` for App Store Connect private-key signing.

**Step 2: Restore the localization catalog and package README**

Reuse the historical catalog as the translation baseline, but make its runtime lookup use `KitLocalization`. Document the current package/product and the stable plugin id.

**Step 3: Run package discovery**

Run: `swift package describe`

Expected: the package resolves using only current local package paths and exposes product `PluginAppStoreConnect`.

---

### Task 2: Port models, credentials, API client, caches, and runtime services

**Files:**
- Create: `Packages/PluginAppStoreConnect/Sources/PluginAppStoreConnect/Models/**`
- Create: `Packages/PluginAppStoreConnect/Sources/PluginAppStoreConnect/Services/**`
- Create: `Packages/PluginAppStoreConnect/Sources/PluginAppStoreConnect/Tools/AppStoreConnectToolSupport.swift`
- Create: `Packages/PluginAppStoreConnect/Sources/PluginAppStoreConnect/Utilities/**`

**Step 1: Port pure models and request/response payloads**

Preserve the historical App Store Connect JSON:API models, version/localization validation, screenshot display specifications, Xcode Cloud models, and create/update payloads. Replace old shared promo imports with `KitAppStorePromo` only where the current shared display preset is needed.

**Step 2: Port persistence and API services**

Use `ProviderStorage.StorageProviding` for plugin directories, `KitKeychain` or the current Security-backed implementation for credentials, and `ProviderNetwork.NetworkProviding` for HTTP. Keep JWT generation, upload-range handling, cache policy/invalidation, and screenshot image caching behavior. Make all shared service state explicitly safe for the current Swift concurrency checks.

**Step 3: Port tool support and all historical tools**

Migrate every historical App Store Connect Agent tool to `KitAgentTool.SuperAgentTool`, including current argument/schema/risk/display-description requirements. Tools must resolve the configured network service through the plugin runtime and return actionable localized errors when credentials or network are unavailable.

**Step 4: Run focused service tests**

Run: `swift test --filter AppStoreConnectPluginTests`

Expected: model, payload, cache, credential, and tool registration tests pass before UI integration is added.

---

### Task 3: Rebuild the plugin UI and Provider contributions

**Files:**
- Create: `Packages/PluginAppStoreConnect/Sources/PluginAppStoreConnect/AppStoreConnectPlugin.swift`
- Create: `Packages/PluginAppStoreConnect/Sources/PluginAppStoreConnect/Views/**`
- Create: `Packages/PluginAppStoreConnect/Sources/PluginAppStoreConnect/ViewModels/**`
- Modify: `Packages/PluginAppStoreConnect/Sources/PluginAppStoreConnect/Services/AppStoreConnectLocalization.swift`

**Step 1: Implement current plugin metadata and lifecycle**

Conform to `SuperPlugin` (and `AsyncSuperPlugin` only if startup network/image-cache preparation requires it). Use the stable plugin id, localized metadata, `.integration` category, `.preview` stage, and `.disabledByDefault` policy. Register About/Manual entries in `onRegister`, register Agent tools and UI contributions in `onBoot`, and remove every contribution in `onShutdown`/`onUnregister`.

**Step 2: Register current workbench contributions**

Register an ActivityBar entry with id `\(id).entry`, a Rail tab with a stable plugin-scoped id, the main content view, toolbar categories, chat context/width profile, and the plugin's root title/help UI. The ActivityBar entry must use the default footer policy from the current ActivityBar implementation, so the recently added global rule hides `contentFooter` while this plugin is active.

**Step 3: Preserve UI behavior while using current providers**

Keep account, app selection, version/localization editing, screenshot management, distribution, and Xcode Cloud pages. Use current `LumiUI` components and current `Provider*` APIs; do not reintroduce old `PanelRailTabItem`, `ViewContainerItem`, `LumiPluginContext`, or legacy section APIs.

**Step 4: Run package build**

Run: `swift build`

Expected: all source files compile under current Swift 6 concurrency and provider APIs.

---

### Task 4: Register the plugin in FactoryLumi

**Files:**
- Modify: `Packages/FactoryLumi/Package.swift`
- Modify: `Packages/FactoryLumi/Sources/FactoryLumi/PluginFactory.swift`

**Step 1: Add the local package and product dependency**

Add `../PluginAppStoreConnect` and product `PluginAppStoreConnect` using the current package naming convention.

**Step 2: Add the plugin to the default plugin list**

Instantiate `AppStoreConnectPlugin()` at its historical order boundary near the other design/integration plugins. Do not add special-case handling to `KernelCore` or `PluginActivityBar`.

**Step 3: Verify disabled-by-default behavior**

Confirm the plugin is registered for metadata/settings discovery but does not boot or expose its ActivityBar entry/tools until enabled by the user.

---

### Task 5: Add regression coverage and finalize

**Files:**
- Create: `Packages/PluginAppStoreConnect/Tests/**`
- Modify: `Packages/FactoryLumi/Tests/**` if factory composition coverage needs an assertion

**Step 1: Add identity and metadata tests**

Verify stable id, localized name, integration category, preview stage, disabled-by-default policy, package localization, and current product/module naming.

**Step 2: Add contribution lifecycle tests**

Using lightweight test providers, verify ActivityBar/Rail/Content/Docs/ToolManager contributions are registered and removed, and that no contribution remains after shutdown.

**Step 3: Add API/model regression tests**

Cover credentials, JWT/request construction, JSON:API decoding, version/localization payloads, screenshot display sizing, cache invalidation, and Xcode Cloud payloads.

**Step 4: Run verification**

Run:

```bash
swift test --package-path Packages/PluginAppStoreConnect
swift test --package-path Packages/FactoryLumi
git diff --check
git status --short
```

Expected: all focused tests pass, no whitespace errors remain, and only the intended package/factory/plan files are modified.

**Step 5: Commit**

```bash
git add Packages/PluginAppStoreConnect Packages/FactoryLumi docs/plans/2026-09-01-app-store-connect-plugin.md
git commit -m "feat(app-store-connect): restore current plugin"
```
