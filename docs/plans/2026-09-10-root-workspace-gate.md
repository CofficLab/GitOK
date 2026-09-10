# Root Workspace Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `PluginRootView` own the current-project gate so unavailable projects render a stable empty/missing-project view without mounting Git-dependent plugin views.

**Architecture:** Keep toolbar and project Sidebar available at all times. Add a root-level workspace state (`noProject`, `projectMissing`, `ready`) and let the root layout choose between the injected workbench and the appropriate empty-project view. Move the missing-project UI/observation into `PluginRootView`; remove the specialized `PluginProjectMissing` plugin and its factory dependency. Rail-specific project hiding becomes unnecessary; retain local defensive guards in business views where useful.

**Tech Stack:** Swift 6, SwiftUI, Combine, Swift Package Manager, KernelCore provider/plugin contracts.

---

### Task 1: Add workspace state and root-layout gate

**Files:**
- Modify: `Packages/ProviderRootView/Sources/ProviderRootView/RootViewProviding.swift`
- Modify: `Packages/ProviderRootView/Sources/ProviderRootView/DefaultRootViewProvider.swift`
- Modify: `Packages/ProviderRootView/Sources/ProviderRootView/Views/DefaultRootHostView.swift`
- Test: `Packages/ProviderRootView/Tests/ProviderRootViewTests/ProviderRootViewTests.swift`

Add a small public workspace-state contract and a replaceable unavailable-workspace view. The host must keep toolbar/sidebar rendering but use the unavailable view instead of `WorkbenchSplitView` whenever state is not `ready`. Test state propagation and the gate-facing provider API.

### Task 2: Move missing-project presentation into RootViewPlugin

**Files:**
- Create or move: `Packages/PluginRootView/Sources/PluginRootView/Views/ProjectMissingView.swift`
- Create: `Packages/PluginRootView/Sources/PluginRootView/Views/ProjectMissingView.swift`
- Create: `Packages/PluginRootView/Sources/PluginRootView/ViewModels/RootWorkspaceModel.swift`
- Modify: `Packages/PluginRootView/Sources/PluginRootView/RootViewPlugin.swift`
- Test: `Packages/PluginRootView/Tests/PluginRootViewTests/PluginRootViewTests.swift`

Observe project list/selection changes, derive `RootWorkspaceState`, and inject a stable unavailable-workspace view into the root provider. `noProject` continues to support add/clone guidance, while `projectMissing` shows the path and remove action. The observer updates synchronously from the already-main-actor project snapshot.

### Task 3: Remove the specialized ProjectMissing plugin

**Files:**
- Delete: `Packages/PluginProjectMissing/`
- Modify: `Packages/FactoryGitOK/Sources/FactoryGitOK/PluginFactory.swift`
- Modify: `Packages/FactoryGitOK/Package.swift`
- Modify: `Packages/Package.swift` or project package references if present

Remove registration, package dependency, metadata/docs registration, and tests for the standalone plugin. Ensure the root plugin now covers all user-visible missing/no-project behavior.

### Task 4: Remove redundant Rail project hiding

**Files:**
- Modify: `Packages/PluginRailView/Sources/PluginRailView/GitOKRailViewProvider.swift`
- Modify: `Packages/PluginRailView/Sources/PluginRailView/RailViewPlugin.swift`
- Modify: `Packages/PluginRailView/Sources/PluginRailView/Views/RailView.swift`
- Delete: `Packages/PluginRailView/Sources/PluginRailView/Capabilities/RailViewProjectCapability.swift`
- Delete: `Packages/PluginRailView/Sources/PluginRailView/Observers/RailViewProjectObserver.swift`
- Test: `Packages/PluginRailView/Tests/PluginRailViewTests/RailViewPluginTests.swift`

Make Rail responsible only for Rail sections/tabs. Remove the duplicate project-availability state and observer, since the root gate prevents Rail from mounting for unavailable projects.

### Task 5: Verify package and application builds

Run:
- `swift test` in `Packages/ProviderRootView`
- `swift test` in `Packages/PluginRootView`
- `swift test` in `Packages/PluginRailView`
- `xcodebuild -project GitOK.xcodeproj -scheme GitOK -configuration Debug -derivedDataPath /tmp/GitOK-Codex-DerivedData build CODE_SIGNING_ALLOWED=NO`

Also run `git diff --check` and verify unrelated existing worktree changes remain unstaged and untouched.
