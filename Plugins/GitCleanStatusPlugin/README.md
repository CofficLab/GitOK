# GitCleanStatusPlugin

Provides tools to clean the working directory by discarding uncommitted changes.

## Overview

This plugin registers with ID `GitCleanStatusPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitCleanStatusPlugin/
├── Package.swift
├── Sources/GitCleanStatusPlugin/
│   ├── GitCleanStatusPlugin.swift
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
