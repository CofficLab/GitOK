# PluginConflictResolver

Detects and helps resolve Git merge conflicts with a dedicated UI and status tile.

## Overview

This plugin registers with ID `ConflictResolverPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginConflictResolver/
├── Package.swift
├── Sources/PluginConflictResolver/
│   ├── ConflictResolverPlugin.swift
│   ├── ConflictResolverList.swift
│   ├── ConflictResolverRow.swift
│   ├── ConflictResolverState.swift
│   ├── ConflictResolverDesignTokens.swift
│   ├── ConflictStatusTile.swift
│   └── Resources/GitConflictResolver.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitCoreKit`
- `GitOKUI`
- `ProjectSupportKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
