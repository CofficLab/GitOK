# ThemeOneDarkPlugin

Classic editor dark theme.

## Overview

This plugin registers with ID `ThemeOneDarkPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeOneDarkPlugin/
├── Package.swift
├── Sources/ThemeOneDarkPlugin/
│   ├── OneDarkThemePlugin.swift
│   ├── OneDarkTheme.swift
│   └── Resources/ThemeOneDark.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `136` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
