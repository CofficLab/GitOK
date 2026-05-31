# PluginIconTab

Registers the Icon tab in the main tab bar.

## Overview

This plugin registers with ID `IconTabPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginIconTab/
├── Package.swift
├── Sources/PluginIconTab/
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
