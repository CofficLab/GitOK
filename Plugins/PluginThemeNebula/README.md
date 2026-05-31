# PluginThemeNebula

Violet atmospheric dark theme.

## Overview

This plugin registers with ID `ThemeNebulaPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeNebula/
├── Package.swift
├── Sources/PluginThemeNebula/
│   ├── NebulaThemePlugin.swift
│   ├── NebulaTheme.swift
│   └── Resources/ThemeNebula.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `126` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
