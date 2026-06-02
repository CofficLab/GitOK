# CleanStatusPlugin

Provides tools to clean the working directory by discarding uncommitted changes.

## Overview

This plugin registers with ID `CleanStatusPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
CleanStatusPlugin/
├── Package.swift
├── Sources/CleanStatusPlugin/
│   ├── CleanStatusPlugin.swift
│   ├── CleanStatusEvents.swift
│   ├── CleanStatusRootView.swift
│   └── Localizable.xcstrings
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
