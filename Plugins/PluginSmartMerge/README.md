# PluginSmartMerge

Detects merge conflicts and provides smart merge resolution with a status tile.

## Overview

This plugin registers with ID `SmartMergePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginSmartMerge/
├── Package.swift
├── Sources/PluginSmartMerge/
│   ├── SmartMergePlugin.swift
│   ├── SmartMergeStatusTile.swift
│   └── Resources/GitMerge.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
