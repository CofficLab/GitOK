# ThemeDraculaPlugin

Classic vivid dark theme.

## Overview

This plugin registers with ID `ThemeDraculaPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeDraculaPlugin/
├── Package.swift
├── Sources/ThemeDraculaPlugin/
│   ├── DraculaThemePlugin.swift
│   ├── DraculaTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `135` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
