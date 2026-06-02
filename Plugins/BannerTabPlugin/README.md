# BannerTabPlugin

Registers the Banner tab in the main tab bar.

## Overview

This plugin registers with ID `BannerTabPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
BannerTabPlugin/
├── Package.swift
├── Sources/BannerTabPlugin/
│   ├── BannerTabPlugin.swift
│   └── Resources/BannerTab.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
