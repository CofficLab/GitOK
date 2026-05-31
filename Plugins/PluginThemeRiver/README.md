# PluginThemeRiver

Flowing teal dark theme.

## Overview

This plugin registers with ID `ThemeRiverPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeRiver/
├── Package.swift
├── Sources/PluginThemeRiver/
│   ├── RiverThemePlugin.swift
│   ├── RiverTheme.swift
│   └── Resources/ThemeRiver.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `125` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
