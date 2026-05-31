# PluginGitLFS

Monitors Git Large File Storage (LFS) status with a status bar tile.

## Overview

This plugin registers with ID `GitLFSPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginGitLFS/
├── Package.swift
├── Sources/PluginGitLFS/
│   ├── GitLFSPlugin.swift
│   ├── GitLFSStatusTile.swift
│   └── Resources/GitLFS.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`
- `GitCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
