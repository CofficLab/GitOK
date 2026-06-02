# ThemeOrchardPlugin

Earthy amber dark theme.

## Overview

This plugin registers with ID `ThemeOrchardPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeOrchardPlugin/
├── Package.swift
├── Sources/ThemeOrchardPlugin/
│   ├── OrchardThemePlugin.swift
│   ├── OrchardTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `128` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
