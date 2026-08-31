# GitRemoteRepositoryPlugin

Manages Git remote repositories with add, remove, and edit capabilities.

## Overview

This plugin registers with ID `GitRemoteRepositoryPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitRemoteRepositoryPlugin/
├── Package.swift
├── Sources/GitRemoteRepositoryPlugin/
│   ├── GitRemoteRepositoryPlugin.swift
│   ├── RemoteRepositoryView.swift
│   ├── RemoteRepositoryRowView.swift
│   ├── RemoteRepositorySheets.swift
│   ├── RemoteRepositoryStatusButton.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitOKCore`
- `KitGitCore`
- `KitProjectRules`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
