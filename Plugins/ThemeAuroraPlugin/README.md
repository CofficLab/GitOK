# ThemeAuroraPlugin

Deep cyan night theme.

## Overview

This plugin registers with ID `ThemeAuroraPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeAuroraPlugin/
├── Package.swift
├── Sources/ThemeAuroraPlugin/
│   ├── AuroraThemePlugin.swift
│   ├── AuroraTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `122` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
