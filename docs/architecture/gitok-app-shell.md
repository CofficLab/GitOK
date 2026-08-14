# GitOK App Shell Architecture

GitOK follows the same layered model as Lumi:

```text
GitOKApp/          Thin shell (~LumiApp): @main scene declarations, MacAgent,
                  Sparkle channel-specific commands
Packages/
  GitOKFactoryCore/   Host engine (Lumi FactoryCore equivalent): RootContainer,
                      RootView, layout views, app services, settings window,
                      menu commands — plugin-agnostic
  GitOKCoreKit/       Plugin SDK + kernel (Lumi KernelLumi equivalent)
  GitCoreKit/         Git engine (git CLI wrapper)
  GitOKUI/            Design system (Lumi LumiUI equivalent)
  …                   Domain kits
Plugins/           Feature SPM packages (one plugin per directory)
GitOKPluginRegistry/  Compile-time plugin catalog + GitOKFactory facade
                      (Lumi FactoryLumi equivalent: makeMainWindow() /
                      makeCommands() / makeSettingsWindow())
```

## Dependency rules

| Layer | May import |
|-------|------------|
| GitOKApp | GitOKFactoryCore, GitOKPluginRegistry, domain kits |
| GitOKFactoryCore | GitOKAppCore, GitOKCoreKit, GitOKUI, domain kits — **no plugins** |
| GitOKPluginRegistry | GitOKFactoryCore + all plugins (composition layer) |
| Plugins | GitOKCoreKit, domain kits |
| GitOKCoreKit | Foundation, GitOKUI, GitCoreKit (no Plugins) |
| Plugins | **Must not** import GitOKApp or GitOKFactoryCore |

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

- `@main` scene declarations calling `GitOKFactory.makeMainWindow()` /
  `makeCommands()` / `makeSettingsWindow()` (LumiApp → FactoryLumi pattern)
- Channel-specific pieces only: Sparkle `UpdateManager`, `AppCommand`
  (check-for-updates menu), `MacAgent`
- Plugin composition lives in `GitOKPluginRegistry/GitOKFactory`, which
  injects the plugin catalog, plugin runtime hooks and sidebar chrome into
  the plugin-agnostic `RootContainer` via `RootContainer.configure(_:)`

Feature UI and business logic belong in Plugins or Packages, not GitOKApp.
The host engine (RootContainer/RootView, layout views, `PluginService`, app
services, commands) lives in `Packages/GitOKFactoryCore`; shell-owned chrome
is injected through `GitOKFactoryChrome` instead of hard dependencies.

## Boundary check

Run from repository root:

```bash
bash Scripts/check-plugin-package-boundaries.sh
```

CI runs the same script in `.github/workflows/boundaries.yaml`.
