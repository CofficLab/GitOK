# ThemeMountainPlugin

Quiet stone light theme.

## Overview

This plugin registers with ID `ThemeMountainPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeMountainPlugin/
├── Package.swift
├── Sources/ThemeMountainPlugin/
│   ├── MountainThemePlugin.swift
│   ├── MountainTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `132` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
