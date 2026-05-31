# PluginOpenTrae

Opens the current project in Trae IDE.

## Overview

This plugin registers with ID `OpenTrae` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginOpenTrae/
├── Package.swift
├── Sources/PluginOpenTrae/
│   ├── OpenTraePlugin.swift
│   ├── OpenTraeButton.swift
│   ├── TraeProjectLauncher.swift
│   └── Resources/OpenTrae.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
