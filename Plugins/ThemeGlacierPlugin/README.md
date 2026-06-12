# ThemeGlacierPlugin

Icy cyan light theme.

## Overview

This plugin registers with ID `ThemeGlacierPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeGlacierPlugin/
├── Package.swift
├── Sources/ThemeGlacierPlugin/
│   ├── GlacierThemePlugin.swift
│   ├── GlacierTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `129` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
