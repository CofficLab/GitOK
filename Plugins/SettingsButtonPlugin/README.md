# SettingsButtonPlugin

Provides a settings button in the toolbar to open app preferences.

## Overview

This plugin registers with ID `SettingsButton` and provides functionality through the GitOK plugin system.

## Architecture

```
SettingsButtonPlugin/
├── Package.swift
├── Sources/SettingsButtonPlugin/
│   ├── SettingsButtonPlugin.swift
│   ├── SettingsButtonView.swift
│   └── Resources/SettingsButton.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
