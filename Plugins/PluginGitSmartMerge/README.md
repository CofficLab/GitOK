# PluginGitSmartMerge

Detects merge conflicts and provides merge resolution with a status tile.

## Overview

This plugin registers with ID `GitMergePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginGitSmartMerge/
├── Package.swift
├── Sources/
│   ├── GitSmartMergePlugin.swift
│   ├── SmartMergeStatusTile.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitCore`
- `KitGitOKCore`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
