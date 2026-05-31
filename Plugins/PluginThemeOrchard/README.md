# PluginThemeOrchard

Earthy amber dark theme.

## Overview

This plugin registers with ID `ThemeOrchardPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeOrchard/
├── Package.swift
├── Sources/PluginThemeOrchard/
│   ├── OrchardThemePlugin.swift
│   ├── OrchardTheme.swift
│   └── Resources/ThemeOrchard.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `128` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
