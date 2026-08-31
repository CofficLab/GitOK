# GitWatcherPlugin

Watches the Git directory for file system changes and triggers refresh events.

## Overview

This plugin registers with ID `GitWatcherPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitWatcherPlugin/
├── Package.swift
├── Sources/GitWatcherPlugin/
│   ├── GitWatcherPlugin.swift
│   ├── GitDirectoryWatcher.swift
│   ├── GitWatcherRootView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitOKCore`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
