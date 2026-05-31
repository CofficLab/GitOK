# PluginThemeMountain

Quiet stone light theme.

## Overview

This plugin registers with ID `ThemeMountainPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeMountain/
├── Package.swift
├── Sources/PluginThemeMountain/
│   ├── MountainThemePlugin.swift
│   ├── MountainTheme.swift
│   └── Resources/ThemeMountain.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `132` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
