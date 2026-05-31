# PluginGitTab

Registers the Git tab in the main tab bar.

## Overview

This plugin registers with ID `GitTabPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginGitTab/
├── Package.swift
├── Sources/PluginGitTab/
│   ├── GitTabPlugin.swift
│   └── Resources/GitTab.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
