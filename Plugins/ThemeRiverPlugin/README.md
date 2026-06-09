# ThemeRiverPlugin

Flowing teal dark theme.

## Overview

This plugin registers with ID `ThemeRiverPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeRiverPlugin/
├── Package.swift
├── Sources/ThemeRiverPlugin/
│   ├── RiverThemePlugin.swift
│   ├── RiverTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `125` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
