# ReadmePlugin

Renders and displays the project's README file with a status icon indicator.

## Overview

This plugin registers with ID `ReadmePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
ReadmePlugin/
├── Package.swift
├── Sources/ReadmePlugin/
│   ├── ReadmePlugin.swift
│   ├── ReadmeViewer.swift
│   ├── ReadmeStatusIcon.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `ProjectSupportKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
