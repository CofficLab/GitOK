# PluginOpenFinder

Opens the current project directory in macOS Finder.

## Overview

This plugin registers with ID `OpenFinder` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginOpenFinder/
├── Package.swift
├── Sources/PluginOpenFinder/
│   ├── OpenFinderPlugin.swift
│   ├── OpenFinderButton.swift
│   └── Resources/OpenFinder.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
