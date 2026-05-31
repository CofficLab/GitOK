# PluginCleanStatus

Provides tools to clean the working directory by discarding uncommitted changes.

## Overview

This plugin registers with ID `CleanStatusPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginCleanStatus/
├── Package.swift
├── Sources/PluginCleanStatus/
│   ├── CleanStatusPlugin.swift
│   ├── CleanStatusEvents.swift
│   ├── CleanStatusRootView.swift
│   └── Resources/CleanStatus.xcstrings
└── Tests/
```

## Dependencies

- `GitCoreKit`
- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
