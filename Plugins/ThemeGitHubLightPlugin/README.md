# ThemeGitHubLightPlugin

GitHub-inspired light theme.

## Overview

This plugin registers with ID `ThemeGitHubLightPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeGitHubLightPlugin/
├── Package.swift
├── Sources/ThemeGitHubLightPlugin/
│   ├── GitHubLightThemePlugin.swift
│   ├── GitHubLightTheme.swift
│   └── Resources/ThemeGitHubLight.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `138` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
