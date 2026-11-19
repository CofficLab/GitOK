# GitOK App Shell Architecture

GitOK shares one assembly engine with Lumi and the sibling apps: the remote
package **LumiFactory** interprets a host manifest; the app only declares its
differences. There is no local factory package.

```text
GitOKApp/                 Thin shell + host manifest (composition root)
  GitOKApp.swift            @main: KernelBootstrapper(manifest:) + HostMacScenes
  GitOKHostManifest.swift   Brand identity, storage/theme config, provider and
                            view-wiring hooks, feature flags (AX contract)
  GitOKPluginCatalog.swift  Explicit, ordered plugin array (no runtime scanning)
  GitOKExternalOpen.swift   gitok:// / Finder directory-open semantics
  ExternalOpenRequest.swift URL ⇄ path codec shared with the CLI script
  AppLocalization.swift     App-layer strings via KitGitOKLocalization
Packages/
  KitGitOKUpdate/           Sparkle auto-update, injected at app layer
  KitGitOKLocalization/     Language-override-aware localization resolver
  KitGit/                   Git domain contracts
  Provider*/                Capability providers (Git, Projects, RootView, …)
  Plugin*/                  Feature plugins (one SPM package per plugin)
Remote (github.com/lumi-softworks):
  LumiFactory               Assembly engine + shared shell (KernelAssembler,
                            KernelBootstrapper, HostAppDelegate, HostMacScenes,
                            HostCommands, theme bridge, window opener)
  LumiKernel / LumiProviders / LumiUI / LumiSettings / LumiThemePack / …
```

## Dependency rules

| Layer | May import |
|-------|------------|
| GitOKApp | LumiFactory, KernelCore, providers, plugins, domain kits |
| Plugins | Provider contracts, domain kits — **never** GitOKApp |
| Providers | KernelCore, domain kits — **never** plugins or GitOKApp |
| LumiFactory | KernelCore + baseline providers only; host differences arrive via `HostManifest` |

The Xcode project (`GitOK.xcodeproj/project.xcproj`) declares every plugin
package directly and links the products into the `GitOK` target; `GitOKTests`
is a hosted unit-test target, `GitOKUITests` drives the app through AX.

## Runtime bootstrap

1. `GitOKApp.init` creates `KernelBootstrapper(manifest: GitOKHostManifest.make { … })`
   and injects it into the shared `HostAppDelegate`.
2. `KernelAssembler` (LumiFactory) runs the pipeline: baseline providers →
   storage/infrastructure migration → `registerProviders` hook → plugin catalog
   validation/sort/atomic start → settings first-entry reset → shared view
   wiring → `wireKernel` hook.
3. `HostMacScenes` renders the three boot states (loading / ready / failed)
   into the main and settings windows; `HostCommands` installs ⌘,, the
   update check and plugin-contributed menus.

The root view is host-owned: the manifest supplies `GitOKRootViewProvider`;
`RootViewPlugin` adopts it on boot and only contributes workspace gating
(noProject / projectMissing / cloning / cloneFailed / notGitRepository / ready).

## GitOK-specific manifest points

- `appliesWindowContentIdentifiers = false` + `usesReadyMarkerOverlays = true`:
  UI tests rely on ~60 descendant AX identifiers that container-level ids
  would shadow; readiness is exposed as 1×1 overlays `gitok.main.ready` /
  `gitok.settings.ready`.
- Theme and root-view persistence directories are pointed back at the plugin
  data directories so existing user selections survive the shared baseline.
- `openExternalPath` decodes `gitok://open?path=…` (see `ExternalOpenRequest`)
  and opens the directory through `ProjectProviding`.
- Debug builds honor `GITOK_UI_TEST_DATA_ROOT` to isolate test data roots.

## Adding a plugin

1. Implement the plugin in `Packages/Plugin<Name>/` (SuperPlugin contract).
2. Add it to `GitOKApp/GitOKPluginCatalog.swift` at the right order band.
3. Declare the package + product in `GitOK.xcodeproj/project.xcproj` for
   **both** the `GitOK` and `GitOKTests` targets. This applies to every
   local package in the graph, including transitive kits/providers. Test
   builds turn every test-linked product into a dynamic framework; an
   app-only local product would statically merge shared dependency code
   and split provider type identities (see docs/plugins/architecture.md).

Test code coverage is disabled (scheme `codeCoverageEnabled = NO`; scripted
runs also pass `-enableCodeCoverage NO`): Xcode's default coverage
instrumentation breaks the C products (swift-cmark) when they are built as
dynamic package frameworks.

Feature UI and business logic belong in plugin/provider packages, not
GitOKApp; the app keeps only the manifest, the catalog and shell glue.