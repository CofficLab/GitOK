# OpenFinderPlugin

Opens the current project directory in macOS Finder.

## Overview

This plugin registers with ID `OpenFinder` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenFinderPlugin/
├── Package.swift
├── Sources/OpenFinderPlugin/
│   ├── OpenFinderPlugin.swift
│   ├── OpenFinderButton.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
