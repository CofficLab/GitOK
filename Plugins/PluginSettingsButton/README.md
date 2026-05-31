# PluginSettingsButton

Provides a settings button in the toolbar to open app preferences.

## Overview

This plugin registers with ID `SettingsButton` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginSettingsButton/
├── Package.swift
├── Sources/PluginSettingsButton/
│   ├── SettingsButtonPlugin.swift
│   ├── SettingsButtonView.swift
│   └── Resources/SettingsButton.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
