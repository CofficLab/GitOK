# PluginThemeSpring

Fresh green light theme.

## Overview

This plugin registers with ID `ThemeSpringPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeSpring/
├── Package.swift
├── Sources/PluginThemeSpring/
│   ├── SpringThemePlugin.swift
│   ├── SpringTheme.swift
│   └── Resources/ThemeSpring.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `121` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
