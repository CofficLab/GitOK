# PluginThemeGitOK

Default GitOK dark theme.

## Overview

This plugin registers with ID `ThemeGitOKPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeGitOK/
├── Package.swift
├── Sources/PluginThemeGitOK/
│   ├── GitOKThemePlugin.swift
│   ├── GitOKTheme.swift
│   └── Resources/ThemeGitOK.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `120` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
