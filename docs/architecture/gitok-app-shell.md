# GitOK App Shell Architecture

GitOK uses the same composition-root model as Lumi:

```text
GitOKApp/          Thin shell (= LumiApp): @main scenes and one shared
                  KernelCoreContainer
Packages/
  KernelCore/         Generic typed Provider registry + kernel lifecycle
  FactoryCore/   Host engine (Lumi FactoryCore equivalent): KernelFactory,
                      ProviderFactory, ViewFactory, RootContainer compatibility
                      graph, MacAgent, RootView, layout and commands
  KitGitOKUpdate/     Sparkle auto-update (Lumi AppUpdatePlugin equivalent):
                      UpdateManager + UpdateCommand, injected at app layer
  KitGitOKCore/       GitOK domain contracts and legacy plugin SDK bridge
  KitGitCore/         Git engine (git CLI wrapper)
  GitOKUI/            Design system (Lumi LumiUI equivalent)
  …                   Domain kits
Plugins/           Feature SPM packages (one plugin per directory)
FactoryGitOK/  Compile-time plugin catalog + GitOKFactory facade
                      (Lumi FactoryLumi equivalent: makeKernel() /
                      makeMainWindow(kernel:) / makeSettingsWindow(kernel:))
```

## Dependency rules

| Layer | May import |
|-------|------------|
| GitOKApp | FactoryCore, FactoryGitOK, KernelCore, domain kits |
| KernelCore | Foundation only; no GitOK or feature imports |
| FactoryCore | KernelCore, GitOKAppCore, KitGitOKCore, GitOKUI, domain kits — **no plugins** |
| FactoryGitOK | FactoryCore + all plugins (composition layer) |
| Plugins | KitGitOKCore, domain kits |
| KitGitOKCore | Foundation, GitOKUI, KitGitCore (no Plugins) |
| Plugins | **Must not** import GitOKApp or FactoryCore |

## Provider layer (Lumi-compatible)

`KernelCoreContainer` is the single runtime composition object. Provider
contracts are split by capability instead of being concentrated in the host:

| Provider package | Contract | Default implementation | Consumers |
|------------------|----------|------------------------|-----------|
| `ProviderProject` | `GitOKProjectServicing` | `GitOKProjectService` | project-aware plugins, RootView |
| `ProviderGit` | repository/activity/command services | `GitCoreService` | Git commands and Git plugins |
| `ProviderTheme` | theme selection/contribution services | `ThemeService` + `PluginService` | theme UI and theme plugins |
| `ProviderNavigation` | `GitOKNavigationServicing` | `AppNavigationService` | commands and settings plugins |

`FactoryCore.ProviderFactory` owns the construction hooks for these providers;
`DefaultProviderFactory` supplies the app defaults. `RootContainer` is now a
compatibility holder that invokes those hooks and registers the typed contracts
in Kernel. New code resolves providers from Kernel; the old
`GitOKPluginDependencies` resolver remains a migration bridge and mirrors
legacy registrations into the same Kernel.

## Service layer (replaces menu NotificationCenter)

App shell commands and plugins call typed services registered in `RootContainer`:

| Former notification | Service |
|----------------------|---------|
| `.gitCommandRefresh` / `.fetch` / `.pull` / `.push` | `GitCoreService.performGitCommand(_:)` via `GitOKGitCommandServicing` |
| `.openSettings` / plugin/repo/commit-style settings | `AppNavigationService` via `GitOKNavigationServicing` |

`GitOKApp/Events/ProjectEvents.swift` remains for plugin decoupling (project lifecycle + git directory changes). Settings persistence events (`didSaveGitUserConfig`, etc.) also remain until migrated.

## Plugin registration

1. Implement `GitOKPlugin` in `Plugins/<Name>Plugin/`
2. Add the plugin to `Packages/FactoryGitOK/Sources/GeneratedPluginRegistry.swift`
3. Declare the package dependency in `FactoryGitOK/Package.swift`

Runtime uses SPM explicit registration (not Objective-C runtime scanning).

## Runtime bootstrap

`GitOKFactory.makeKernel()` delegates to `KernelFactory`, which creates the
Kernel first, asks the registry's `PluginFactory` for the compile-time
composition, and asks the host's `ProviderFactory` to assemble the service
graph into that exact Kernel. The resulting Kernel is shared by the main
window, settings window and commands.

`GitOKPluginBootstrap.configureRuntimes(projectService:)` remains a compatibility
hook called after services are wired. It registers plugin singleton callbacks
that need app-side providers (e.g. `AutoPushService` current-project snapshot).

Plugins that receive data through `GitOKPluginContext` (GitWatcher, UnpushedStatus callbacks, etc.) do not need separate bootstrap wiring.

## App shell responsibilities

- Single-file `GitOKApp.swift` (= LumiApp): `@main` scene declarations. It
  assembles one Kernel in `init`, caches the main/settings views, and calls
  `GitOKFactory.makeMainWindow(kernel:)` / `makeCommands(kernel:)` /
  `makeSettingsWindow(kernel:)`, plus channel-specific wiring — the Sparkle launch
  hook and `UpdateCommand()` from `KitGitOKUpdate` (mirrors Lumi injecting
  `AppUpdatePlugin` at the `LumiApp` layer; an MAS variant could drop it)
- `MacAgent` lives in `FactoryCore/Bootstrap/` (as in Lumi FactoryCore)
  and runs channel-specific launch work through `GitOKFactoryChrome.launchHooks`
- Plugin composition lives in `FactoryGitOK/GitOKFactory`, which
  implements `PluginFactory` and hands its composition to `KernelFactory`.

Feature UI and business logic belong in Plugins or Packages, not GitOKApp.
The host engine (KernelFactory, RootContainer compatibility graph, RootView,
layout views, `PluginService`, app services, commands) lives in
`Packages/FactoryCore`; shell-owned chrome is injected through
`GitOKFactoryChrome` instead of hard dependencies.

## Boundary check

Run from repository root:

```bash
bash Scripts/check-plugin-package-boundaries.sh
```

CI runs the same script in `.github/workflows/boundaries.yaml`.
