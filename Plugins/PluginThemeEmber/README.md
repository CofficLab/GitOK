# PluginThemeEmber

Warm orange dark theme.

## Overview

This plugin registers with ID `ThemeEmberPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeEmber/
├── Package.swift
├── Sources/PluginThemeEmber/
│   ├── EmberThemePlugin.swift
│   ├── EmberTheme.swift
│   └── Resources/ThemeEmber.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `124` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
