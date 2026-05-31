# PluginThemeGraphite

Neutral graphite dark theme.

## Overview

This plugin registers with ID `ThemeGraphitePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeGraphite/
├── Package.swift
├── Sources/PluginThemeGraphite/
│   ├── GraphiteThemePlugin.swift
│   ├── GraphiteTheme.swift
│   └── Resources/ThemeGraphite.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `134` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
