# PluginGitPull

Provides a toolbar button to pull changes from the remote repository.

## Overview

This plugin registers with ID `GitPullPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginGitPull/
├── Package.swift
├── Sources/PluginGitPull/
│   ├── GitPullPlugin.swift
│   ├── GitPullButton.swift
│   └── Resources/GitPull.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
