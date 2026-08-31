# GitSubmodulePlugin

Manages Git submodules with status monitoring and update operations.

## Overview

This plugin registers with ID `GitSubmodulePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitSubmodulePlugin/
├── Package.swift
├── Sources/GitSubmodulePlugin/
│   ├── GitSubmodulePlugin.swift
│   ├── SubmoduleEvents.swift
│   ├── SubmodulePresentation.swift
│   ├── SubmoduleStatusTile.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitCore`
- `KitGitOKCore`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
