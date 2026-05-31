# PluginRemoteRepository

Manages Git remote repositories with add, remove, and edit capabilities.

## Overview

This plugin registers with ID `RemoteRepositoryPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginRemoteRepository/
├── Package.swift
├── Sources/PluginRemoteRepository/
│   ├── RemoteRepositoryPlugin.swift
│   ├── RemoteRepositoryView.swift
│   ├── RemoteRepositoryRowView.swift
│   ├── RemoteRepositorySheets.swift
│   ├── RemoteRepositoryStatusButton.swift
│   └── Resources/GitRemoteRepository.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitCoreKit`
- `ProjectRulesKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
