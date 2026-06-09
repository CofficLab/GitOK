# ThemeGraphitePlugin

Neutral graphite dark theme.

## Overview

This plugin registers with ID `ThemeGraphitePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeGraphitePlugin/
├── Package.swift
├── Sources/ThemeGraphitePlugin/
│   ├── GraphiteThemePlugin.swift
│   ├── GraphiteTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `134` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
