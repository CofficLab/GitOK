# PluginUnpushedStatus

Displays the number of unpushed commits in the status bar and provides a root view for details.

## Overview

This plugin registers with ID `UnpushedStatusPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginUnpushedStatus/
├── Package.swift
├── Sources/PluginUnpushedStatus/
│   ├── UnpushedStatusPlugin.swift
│   ├── UnpushedStatusRootView.swift
│   ├── UnpushedStatusEvents.swift
│   └── Resources/UnpushedStatus.xcstrings
└── Tests/
```

## Dependencies

- `GitCoreKit`
- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
