# StashPlugin

Manages Git stashes with list view, create, apply, pop, and drop operations.

## Overview

This plugin registers with ID `StashPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
StashPlugin/
├── Package.swift
├── Sources/StashPlugin/
│   ├── StashPlugin.swift
│   ├── StashListView.swift
│   ├── StashRow.swift
│   ├── StashEvents.swift
│   ├── StashPresentation.swift
│   ├── StashStatusTile.swift
│   └── Resources/GitStash.xcstrings
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
