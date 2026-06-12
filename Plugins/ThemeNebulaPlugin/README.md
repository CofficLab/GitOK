# ThemeNebulaPlugin

Violet atmospheric dark theme.

## Overview

This plugin registers with ID `ThemeNebulaPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeNebulaPlugin/
├── Package.swift
├── Sources/ThemeNebulaPlugin/
│   ├── NebulaThemePlugin.swift
│   ├── NebulaTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `126` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
