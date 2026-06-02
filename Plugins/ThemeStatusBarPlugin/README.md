# ThemeStatusBarPlugin

Provides a theme picker popover in the status bar for switching between installed themes.

## Overview

This plugin registers with ID `ThemeStatusBarPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ThemeStatusBarPlugin/
├── Package.swift
├── Sources/ThemeStatusBarPlugin/
│   ├── ThemeStatusBarPlugin.swift
│   ├── ThemeStatusBarView.swift
│   ├── ThemePickerPopover.swift
│   └── Resources/ThemeStatusBar.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
