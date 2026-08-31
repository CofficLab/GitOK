# OpenTraePlugin

Opens the current project in Trae IDE.

## Overview

This plugin registers with ID `OpenTrae` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenTraePlugin/
├── Package.swift
├── Sources/OpenTraePlugin/
│   ├── OpenTraePlugin.swift
│   ├── OpenTraeButton.swift
│   ├── TraeProjectLauncher.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitOKCore`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
