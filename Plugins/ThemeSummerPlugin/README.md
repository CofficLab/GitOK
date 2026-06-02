# ThemeSummerPlugin

Warm golden light theme.

## Overview

This plugin registers with ID `ThemeSummerPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeSummerPlugin/
├── Package.swift
├── Sources/ThemeSummerPlugin/
│   ├── SummerThemePlugin.swift
│   ├── SummerTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `130` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
