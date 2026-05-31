# PluginThemeGlacier

Icy cyan light theme.

## Overview

This plugin registers with ID `ThemeGlacierPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeGlacier/
├── Package.swift
├── Sources/PluginThemeGlacier/
│   ├── GlacierThemePlugin.swift
│   ├── GlacierTheme.swift
│   └── Resources/ThemeGlacier.xcstrings
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
