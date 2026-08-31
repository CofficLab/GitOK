# GitSmartMergePlugin

Detects merge conflicts and provides smart merge resolution with a status tile.

## Overview

This plugin registers with ID `GitSmartMergePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitSmartMergePlugin/
├── Package.swift
├── Sources/GitSmartMergePlugin/
│   ├── GitSmartMergePlugin.swift
│   ├── SmartMergeStatusTile.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitOKCore`
- `KitGitCore`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
