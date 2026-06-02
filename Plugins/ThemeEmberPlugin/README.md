# ThemeEmberPlugin

Warm orange dark theme.

## Overview

This plugin registers with ID `ThemeEmberPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeEmberPlugin/
├── Package.swift
├── Sources/ThemeEmberPlugin/
│   ├── EmberThemePlugin.swift
│   ├── EmberTheme.swift
│   └── Resources/ThemeEmber.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `124` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
