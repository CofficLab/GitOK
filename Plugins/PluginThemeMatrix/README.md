# PluginThemeMatrix

Electric green dark theme.

## Overview

This plugin registers with ID `ThemeMatrixPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeMatrix/
├── Package.swift
├── Sources/PluginThemeMatrix/
│   ├── MatrixThemePlugin.swift
│   ├── MatrixTheme.swift
│   └── Resources/ThemeMatrix.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `131` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
