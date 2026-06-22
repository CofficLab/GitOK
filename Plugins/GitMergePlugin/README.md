# GitMergePlugin

Detects merge conflicts and provides merge resolution with a status tile.

## Overview

This plugin registers with ID `GitMergePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitMergePlugin/
├── Package.swift
├── Sources/GitMergePlugin/
│   ├── GitMergePlugin.swift
│   ├── MergeStatusTile.swift
│   └── Localizable.xcstrings
└── Tests/
    └── GitMergePluginTests.swift
```

## Dependencies

- `GitOKCoreKit`
- `GitCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
