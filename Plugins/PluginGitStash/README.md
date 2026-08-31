# GitStashPlugin

Manages Git stashes with list view, create, apply, pop, and drop operations.

## Overview

This plugin registers with ID `GitStashPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitStashPlugin/
├── Package.swift
├── Sources/GitStashPlugin/
│   ├── GitStashPlugin.swift
│   ├── StashListView.swift
│   ├── StashRow.swift
│   ├── StashEvents.swift
│   ├── StashPresentation.swift
│   ├── StashStatusTile.swift
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
