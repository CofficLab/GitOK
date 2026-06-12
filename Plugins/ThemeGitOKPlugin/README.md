# ThemeGitOKPlugin

Default GitOK dark theme.

## Overview

This plugin registers with ID `ThemeGitOKPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeGitOKPlugin/
├── Package.swift
├── Sources/ThemeGitOKPlugin/
│   ├── GitOKThemePlugin.swift
│   ├── GitOKTheme.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `120` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
