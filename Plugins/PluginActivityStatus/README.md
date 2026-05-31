# PluginActivityStatus

Displays current long-running activity in the status bar.

## Overview

This plugin provides a status bar tile that shows the current activity status of long-running Git operations (e.g., cloning, pushing, pulling). It uses the `gitOKActivityStatus` environment value to read the current activity message and displays it with a spinning indicator icon.

## Features

- **Status Bar Display**: Shows a compact activity indicator in the status bar center area
- **Automatic Updates**: Reacts to `gitOKActivityStatus` environment changes
- **Tooltip**: Displays "Current activity" help text on hover

## Architecture

```
PluginActivityStatus/
├── Sources/
│   └── PluginActivityStatus/
│       ├── ActivityStatusPlugin.swift   # Plugin entry point & metadata
│       ├── ActivityStatusTile.swift     # Status bar tile view
│       └── Resources/
│           └── ActivityStatus.xcstrings # Localized strings
└── Tests/
    └── PluginActivityStatusTests/
        └── ActivityStatusPluginTests.swift
```

## Dependencies

- `GitOKPluginKit` — Plugin protocol and shared infrastructure

## Configuration

| Property       | Value                          |
|---------------|-------------------------------|
| `order`       | `9999` (low priority)         |
| `allowUserToggle` | `false` (always visible)  |
| `defaultEnabled`  | `true`                    |
