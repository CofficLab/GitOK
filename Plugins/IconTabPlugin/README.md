# IconTabPlugin

Registers the Icon tab in the main tab bar.

## Overview

This plugin registers with ID `IconTabPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
IconTabPlugin/
├── Package.swift
├── Sources/IconTabPlugin/
│   ├── IconTabPlugin.swift
│   └── Resources/IconTab.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
