# PluginGitPush

Provides a toolbar button to push local commits to the remote repository.

## Overview

This plugin registers with ID `GitPushPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginGitPush/
├── Package.swift
├── Sources/PluginGitPush/
│   ├── GitPushPlugin.swift
│   ├── GitPushButton.swift
│   └── Resources/GitPush.xcstrings
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
