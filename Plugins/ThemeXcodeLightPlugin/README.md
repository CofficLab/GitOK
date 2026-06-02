# ThemeXcodeLightPlugin

Xcode-inspired light theme.

## Overview

This plugin registers with ID `ThemeXcodeLightPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeXcodeLightPlugin/
├── Package.swift
├── Sources/ThemeXcodeLightPlugin/
│   ├── XcodeLightThemePlugin.swift
│   ├── XcodeLightTheme.swift
│   └── Resources/ThemeXcodeLight.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `137` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
