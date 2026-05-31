# PluginOpenAntigravity

Opens the current project in Antigravity IDE.

## Overview

This plugin registers with ID `OpenAntigravity` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginOpenAntigravity/
├── Package.swift
├── Sources/PluginOpenAntigravity/
│   ├── OpenAntigravityPlugin.swift
│   ├── OpenAntigravityButton.swift
│   ├── AntigravityProjectLauncher.swift
│   └── Resources/OpenAntigravity.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
