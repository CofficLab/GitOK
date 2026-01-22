# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GitOK is a macOS Git project management tool built with SwiftUI, featuring an extensible plugin architecture with 40+ plugins for Git operations, development tools, and productivity features.

## Build Commands

```bash
# Build the application
xcodebuild -scheme GitOK -destination 'platform=macOS' build

# Build for release
xcodebuild -scheme GitOK -configuration Release build

# Clean build
xcodebuild -scheme GitOK clean
```

## Architecture

### Core Providers (The "Big Three")

1. **AppProvider** (`Core/Providers/AppProvider.swift`)
   - Application-level state and configuration
   - Window management and app lifecycle

2. **DataProvider** (`Core/Providers/DataProvider.swift`)
   - Coordinates data access across repositories
   - Manages project, branch, commit state
   - Central data model for the entire application

3. **PluginProvider** (`Core/Providers/PluginProvider.swift`)
   - Automatic plugin discovery via Objective-C runtime
   - Plugin registration and lifecycle management
   - Filters plugins by user settings
   - Provides plugin-contributed UI components

### Plugin System

All plugins conform to `SuperPlugin` protocol (`Core/Contact/SuperPlugin.swift`):

```swift
class MyPlugin: NSObject, SuperPlugin {
    @objc static let shared = MyPlugin()

    // Required properties
    static let shouldRegister = true
    static var allowUserToggle = false
    static var defaultEnabled: Bool = true
    static var displayName: String
    static var description: String
    static var iconName: String

    // View contributions (optional)
    func addDetailView(for tab: String) -> AnyView? { nil }
    func addListView(tab: String, project: Project?) -> AnyView? { nil }
    func addToolBarLeadingView() -> AnyView? { nil }
    func addToolBarTrailingView() -> AnyView? { nil }
    func addStatusBarLeadingView() -> AnyView? { nil }
    func addStatusBarCenterView() -> AnyView? { nil }
    func addStatusBarTrailingView() -> AnyView? { nil }
}
```

**Key Plugin Properties:**
- `shouldRegister`: Whether plugin should register at startup
- `allowUserToggle`: Whether user can enable/disable in settings
- `defaultEnabled`: Default enabled state (when user hasn't configured)

**Plugin Discovery:**
- Scans for classes ending with "Plugin" in "GitOK." namespace
- Uses `@objc static let shared` singleton pattern
- Automatically registers on app launch
- Ordered by `order` property

### Event System

Events are defined in `Core/Events/` and used via modifier extensions:

```swift
// Listen to events
.onProjectDidChangeBranch(perform: onBranchChanged)
.onApplicationDidBecomeActive(perform: onAppActive)

// Post events
NotificationCenter.default.post(name: .projectDidCommit, object: nil)
```

**Important Events:**
- `.projectDidChangeBranch` - Branch changed
- `.projectDidCommit` - New commit created
- `.projectDidPush` - Push completed
- `.projectDidPull` - Pull completed
- `.appDidBecomeActive` - App activated

### Repository Pattern

Data access is abstracted through repositories:
- **ProjectRepo** - Project CRUD operations
- **GitUserConfigRepo** - Git user configuration
- **PluginSettingsStore** - Plugin enable/disable settings (ObservableObject with @Published)
- Plus custom repos per plugin

### Status Display Pattern

Use `data.activityStatus` to show transient status in ActivityStatusTile:

```swift
private func setStatus(_ text: String?) {
    Task { @MainActor in
        data.activityStatus = text
    }
}

// Usage
setStatus("正在处理…")
// ... do work ...
setStatus(nil)  // Clear when done
```

## Code Conventions

### Documentation
- Use Chinese for user-facing strings
- Comprehensive Swift documentation comments
- MARK sections for organization (e.g., `// MARK: - Actions`)

### Logging
Use `SuperLog` protocol for consistent logging:
```swift
struct MyView: View, SuperLog {
    nonisolated static let emoji = "🔧"
    nonisolated static let verbose = false

    // Usage
    if Self.verbose {
        os_log("\(self.t)Detailed message")
    }
}
```

### SwiftUI Views
- Always provide Preview sections
- Use `@MainActor` for view-related classes
- Use Task.detached for heavy work off main actor
- Store cancellables for Combine subscriptions

### Plugin Organization
Each plugin typically contains:
- Main plugin file (e.g., `MyPlugin.swift`)
- View components (e.g., `MyView.swift`)
- Repository/Model files as needed
- Preview section at bottom

## Key Files

### Main Entry Points
- `GitOKApp.swift` - App entry point
- `MacAgent.swift` - App delegate
- `ContentLayout.swift` - Main UI layout
- `RootView.swift` - Root view wrapper

### Core Architecture
- `Core/Contact/SuperPlugin.swift` - Plugin protocol
- `Core/Bootstrap/MagicSuperPlugin.swift` - Base plugin protocol
- `Core/Providers/PluginProvider.swift` - Plugin management
- `Core/Models/PluginSettingsStore.swift` - Plugin settings (ObservableObject)

### Important Plugins
- `Plugins/Git-Commit/CommitList.swift` - Commit list with remote sync checking
- `Plugins/Git-Commit/CurrentWorkingStateView.swift` - Working state display
- `Plugins/Git-Pull/BtnGitPullView.swift` - Pull button
- `Plugins/ActivityStatus/ActivityStatusTile.swift` - Status bar indicator
- `Plugins/Icon/IconPlugin.swift` - App icon generation
- `Plugins/Banner/BannerPlugin.swift` - Banner creation

## Git Operations

The app uses LibGit2Swift for Git operations. Key Project methods:
- `project.getUnPulledCount()` - Get number of commits behind remote
- `project.getUnPushedCommits()` - Get unpushed commits
- `project.pull()` - Execute git pull
- `project.push()` - Execute git push
- `project.getCommitsWithPagination()` - Paginated commit history

## Common Patterns

### Creating a New Plugin
1. Create directory in `Plugins/`
2. Create plugin class conforming to SuperPlugin
3. Implement `shared` singleton with `@objc`
4. Set `shouldRegister = true`
5. Implement view contribution methods
6. Plugin auto-discovers on app launch

### Adding Settings
Settings views go in `Core/Views/Settings/`. Use `SettingView` with tab system:
```swift
SettingView(defaultTab: .plugins) // or .git, .repository, etc.
```

### Timer-Based Background Checks
Pattern for periodic checks (e.g., remote sync):
```swift
@State private var timerCancellable: AnyCancellable? = nil
private let timerInterval: TimeInterval = 60

// Start timer
timerCancellable = Timer.publish(every: timerInterval, on: .main, in: .common)
    .autoconnect()
    .sink { [self] _ in
        self.checkStatus()
    }

// Stop timer
timerCancellable?.cancel()
```

## Dependencies

Key Swift Package Manager dependencies:
- **LibGit2Swift** - Git operations
- **MagicKit** - Core utilities and protocols
- **MagicUI** - UI components
- **Sparkle** - Auto-updates
- **SwiftData** - Persistence

## File Structure Notes

- `Core/` - Application core, not to be confused with project root
- `Plugins/` - All 40+ plugins, each in its own directory
- `.gitok/` - Runtime data directory, not in git
- `scripts/` - Build and deployment automation
