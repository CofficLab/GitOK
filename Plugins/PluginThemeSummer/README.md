# PluginThemeSummer

Warm golden light theme.

## Overview

This plugin registers with ID `ThemeSummerPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeSummer/
├── Package.swift
├── Sources/PluginThemeSummer/
│   ├── SummerThemePlugin.swift
│   ├── SummerTheme.swift
│   └── Resources/ThemeSummer.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `130` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
