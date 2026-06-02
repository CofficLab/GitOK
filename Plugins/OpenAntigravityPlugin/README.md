# OpenAntigravityPlugin

Opens the current project in Antigravity IDE.

## Overview

This plugin registers with ID `OpenAntigravity` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenAntigravityPlugin/
├── Package.swift
├── Sources/OpenAntigravityPlugin/
│   ├── OpenAntigravityPlugin.swift
│   ├── OpenAntigravityButton.swift
│   ├── AntigravityProjectLauncher.swift
│   └── Resources/OpenAntigravity.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
