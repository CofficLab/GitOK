# PluginThemeStatusBar

Provides a theme picker popover in the status bar for switching between installed themes.

## Overview

This plugin registers with ID `ThemeStatusBarPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginThemeStatusBar/
├── Package.swift
├── Sources/PluginThemeStatusBar/
│   ├── ThemeStatusBarPlugin.swift
│   ├── ThemeStatusBarView.swift
│   ├── ThemePickerPopover.swift
│   └── Resources/ThemeStatusBar.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
