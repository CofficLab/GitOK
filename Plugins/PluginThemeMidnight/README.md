# PluginThemeMidnight

Quiet terminal-green dark theme.

## Overview

This plugin registers with ID `ThemeMidnightPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeMidnight/
├── Package.swift
├── Sources/PluginThemeMidnight/
│   ├── MidnightThemePlugin.swift
│   ├── MidnightTheme.swift
│   └── Resources/ThemeMidnight.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `123` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
