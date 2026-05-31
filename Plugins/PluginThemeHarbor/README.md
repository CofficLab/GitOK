# PluginThemeHarbor

Deep blue water theme.

## Overview

This plugin registers with ID `ThemeHarborPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeHarbor/
├── Package.swift
├── Sources/PluginThemeHarbor/
│   ├── HarborThemePlugin.swift
│   ├── HarborTheme.swift
│   └── Resources/ThemeHarbor.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `order`            | `127` |
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
