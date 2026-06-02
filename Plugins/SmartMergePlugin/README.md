# SmartMergePlugin

Detects merge conflicts and provides smart merge resolution with a status tile.

## Overview

This plugin registers with ID `SmartMergePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
SmartMergePlugin/
├── Package.swift
├── Sources/SmartMergePlugin/
│   ├── SmartMergePlugin.swift
│   ├── SmartMergeStatusTile.swift
│   └── Localizable.xcstrings
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
