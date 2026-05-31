# PluginBannerTab

Registers the Banner tab in the main tab bar.

## Overview

This plugin registers with ID `BannerTabPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginBannerTab/
├── Package.swift
├── Sources/PluginBannerTab/
│   ├── BannerTabPlugin.swift
│   └── Resources/BannerTab.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
