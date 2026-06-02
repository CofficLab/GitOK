# GitTabPlugin

Registers the Git tab in the main tab bar.

## Overview

This plugin registers with ID `GitTabPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitTabPlugin/
├── Package.swift
├── Sources/GitTabPlugin/
│   ├── GitTabPlugin.swift
│   └── Resources/GitTab.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
