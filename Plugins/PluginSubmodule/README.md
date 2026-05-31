# PluginSubmodule

Manages Git submodules with status monitoring and update operations.

## Overview

This plugin registers with ID `SubmodulePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginSubmodule/
├── Package.swift
├── Sources/PluginSubmodule/
│   ├── SubmodulePlugin.swift
│   ├── SubmoduleEvents.swift
│   ├── SubmodulePresentation.swift
│   ├── SubmoduleStatusTile.swift
│   └── Resources/GitSubmodule.xcstrings
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
