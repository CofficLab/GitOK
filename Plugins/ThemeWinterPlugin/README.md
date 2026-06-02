# ThemeWinterPlugin

Cool minimal light theme.

## Overview

This plugin registers with ID `ThemeWinterPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeWinterPlugin/
├── Package.swift
├── Sources/ThemeWinterPlugin/
│   ├── WinterThemePlugin.swift
│   ├── WinterTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `133` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
