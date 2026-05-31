# PluginReadme

Renders and displays the project's README file with a status icon indicator.

## Overview

This plugin registers with ID `ReadmePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginReadme/
├── Package.swift
├── Sources/PluginReadme/
│   ├── ReadmePlugin.swift
│   ├── ReadmeViewer.swift
│   ├── ReadmeStatusIcon.swift
│   └── Resources/Readme.xcstrings
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
