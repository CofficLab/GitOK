# PluginThemeXcodeLight

Xcode-inspired light theme.

## Overview

This plugin registers with ID `ThemeXcodeLightPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeXcodeLight/
├── Package.swift
├── Sources/PluginThemeXcodeLight/
│   ├── XcodeLightThemePlugin.swift
│   ├── XcodeLightTheme.swift
│   └── Resources/ThemeXcodeLight.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `137` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
