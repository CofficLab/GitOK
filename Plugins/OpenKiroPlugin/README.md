# OpenKiroPlugin

Opens the current project in Kiro IDE.

## Overview

This plugin registers with ID `OpenKiro` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenKiroPlugin/
├── Package.swift
├── Sources/OpenKiroPlugin/
│   ├── OpenKiroPlugin.swift
│   ├── OpenKiroButton.swift
│   ├── KiroProjectLauncher.swift
│   └── Resources/OpenKiro.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
