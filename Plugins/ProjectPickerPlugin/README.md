# ProjectPickerPlugin

Provides a project picker view for selecting and switching between Git projects.

## Overview

This plugin registers with ID `ProjectPickerPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ProjectPickerPlugin/
├── Package.swift
├── Sources/ProjectPickerPlugin/
│   ├── ProjectPickerPlugin.swift
│   ├── ProjectPickerView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `ProjectRulesKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
