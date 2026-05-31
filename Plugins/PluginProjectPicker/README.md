# PluginProjectPicker

Provides a project picker view for selecting and switching between Git projects.

## Overview

This plugin registers with ID `ProjectPickerPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginProjectPicker/
├── Package.swift
├── Sources/PluginProjectPicker/
│   ├── ProjectPickerPlugin.swift
│   ├── ProjectPickerView.swift
│   └── Resources/ProjectPicker.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `ProjectRulesKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
