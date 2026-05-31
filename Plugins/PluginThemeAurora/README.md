# PluginThemeAurora

Deep cyan night theme.

## Overview

This plugin registers with ID `ThemeAuroraPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeAurora/
├── Package.swift
├── Sources/PluginThemeAurora/
│   ├── AuroraThemePlugin.swift
│   ├── AuroraTheme.swift
│   └── Resources/ThemeAurora.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `122` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
