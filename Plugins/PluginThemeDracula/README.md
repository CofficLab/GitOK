# PluginThemeDracula

Classic vivid dark theme.

## Overview

This plugin registers with ID `ThemeDraculaPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeDracula/
├── Package.swift
├── Sources/PluginThemeDracula/
│   ├── DraculaThemePlugin.swift
│   ├── DraculaTheme.swift
│   └── Resources/ThemeDracula.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `135` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
