# PluginGitWatcher

Watches the Git directory for file system changes and triggers refresh events.

## Overview

This plugin registers with ID `GitWatcherPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginGitWatcher/
├── Package.swift
├── Sources/PluginGitWatcher/
│   ├── GitWatcherPlugin.swift
│   ├── GitDirectoryWatcher.swift
│   ├── GitWatcherRootView.swift
│   └── Resources/GitWatcher.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
