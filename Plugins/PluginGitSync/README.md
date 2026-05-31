# PluginGitSync

Provides a sync button that performs a combined pull-then-push operation.

## Overview

This plugin registers with ID `SyncPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginGitSync/
├── Package.swift
├── Sources/PluginGitSync/
│   ├── GitSyncPlugin.swift
│   ├── GitSyncButton.swift
│   └── Resources/GitSync.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
