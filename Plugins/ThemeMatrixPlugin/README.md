# ThemeMatrixPlugin

Electric green dark theme.

## Overview

This plugin registers with ID `ThemeMatrixPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeMatrixPlugin/
├── Package.swift
├── Sources/ThemeMatrixPlugin/
│   ├── MatrixThemePlugin.swift
│   ├── MatrixTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `131` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
