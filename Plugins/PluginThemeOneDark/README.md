# PluginThemeOneDark

Classic editor dark theme.

## Overview

This plugin registers with ID `ThemeOneDarkPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeOneDark/
├── Package.swift
├── Sources/PluginThemeOneDark/
│   ├── OneDarkThemePlugin.swift
│   ├── OneDarkTheme.swift
│   └── Resources/ThemeOneDark.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `136` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
