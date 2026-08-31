# GitConflictResolverPlugin

Detects and helps resolve Git merge conflicts with a dedicated UI and status tile.

## Overview

This plugin registers with ID `GitConflictResolverPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitConflictResolverPlugin/
├── Package.swift
├── Sources/GitConflictResolverPlugin/
│   ├── GitConflictResolverPlugin.swift
│   ├── ConflictResolverList.swift
│   ├── ConflictResolverRow.swift
│   ├── ConflictResolverState.swift
│   ├── ConflictResolverDesignTokens.swift
│   ├── ConflictStatusTile.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitOKCore`
- `KitGitCore`
- `GitOKUI`
- `KitProjectSupport`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
