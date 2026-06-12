# GitOK App Shell Architecture

GitOK follows the same layered model as Lumi:

```text
GitOKApp/          Thin shell: scenes, DI, NavigationSplitView chrome
Packages/          SDK + domain kits (GitOKCoreKit, GitCoreKit, GitOKUI, …)
Plugins/           Feature SPM packages (one plugin per directory)
GitOKPluginRegistry/  Explicit bundled plugin manifest + runtime bootstrap
```

## Dependency rules

| Layer | May import |
|-------|------------|
| GitOKApp | GitOKCoreKit, GitOKPluginRegistry, GitOKUI, domain kits |
| Plugins | GitOKCoreKit, domain kits |
| GitOKCoreKit | Foundation, GitOKUI, GitCoreKit (no Plugins) |
| Plugins | **Must not** import GitOKApp |

## Service layer (replaces menu NotificationCenter)

App shell commands and plugins call typed services registered in `RootContainer`:

| Former notification | Service |
|----------------------|---------|
| `.gitCommandRefresh` / `.fetch` / `.pull` / `.push` | `GitCoreService.performGitCommand(_:)` via `GitOKGitCommandServicing` |
| `.openSettings` / plugin/repo/commit-style settings | `AppNavigationService` via `GitOKNavigationServicing` |

`GitOKApp/Events/ProjectEvents.swift` remains for plugin decoupling (project lifecycle + git directory changes). Settings persistence events (`didSaveGitUserConfig`, etc.) also remain until migrated.

## Plugin registration

1. Implement `GitOKPlugin` in `Plugins/<Name>Plugin/`
2. Add the plugin to `Packages/GitOKPluginRegistry/Sources/GeneratedPluginRegistry.swift`
3. Declare the package dependency in `GitOKPluginRegistry/Package.swift`

Runtime uses SPM explicit registration (not Objective-C runtime scanning).

## Runtime bootstrap

`GitOKPluginBootstrap.configureRuntimes(projectService:)` is called from `RootContainer` after services are wired. It registers plugin singleton callbacks that need app-side providers (e.g. `AutoPushService` current-project snapshot).

Plugins that receive data through `GitOKPluginContext` (GitWatcher, UnpushedStatus callbacks, etc.) do not need separate bootstrap wiring.

## App shell responsibilities

- `@main`, Sparkle updates, SwiftData `ModelContainer`
- `RootContainer` service wiring + `GitOKPluginBootstrap`
- `PluginService` contribution aggregation
- `ContentView` NavigationSplitView chrome (toolbar, tabs, status bar slots)
- macOS menu commands delegating to services (no NotificationCenter for navigation/git menus)

Feature UI and business logic belong in Plugins or Packages, not GitOKApp.

## Boundary check

Run from repository root:

```bash
bash Scripts/check-plugin-package-boundaries.sh
```

CI runs the same script in `.github/workflows/boundaries.yaml`.
