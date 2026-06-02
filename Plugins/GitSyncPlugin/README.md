# GitSyncPlugin

Provides a sync button that performs a combined pull-then-push operation.

## Overview

This plugin registers with ID `SyncPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitSyncPlugin/
├── Package.swift
├── Sources/GitSyncPlugin/
│   ├── GitSyncPlugin.swift
│   ├── GitSyncButton.swift
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
