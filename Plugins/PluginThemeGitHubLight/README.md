# PluginThemeGitHubLight

GitHub-inspired light theme.

## Overview

This plugin registers with ID `ThemeGitHubLightPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeGitHubLight/
├── Package.swift
├── Sources/PluginThemeGitHubLight/
│   ├── GitHubLightThemePlugin.swift
│   ├── GitHubLightTheme.swift
│   └── Resources/ThemeGitHubLight.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `138` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
