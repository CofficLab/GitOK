# PluginGitClone

Provides a sheet UI for cloning Git repositories with SSH authentication support and credential management.

## Overview

This plugin registers with ID `GitClonePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginGitClone/
├── Package.swift
├── Sources/PluginGitClone/
│   ├── CloneRepositorySheet.swift
│   ├── CloneSSHAuthenticationHelpView.swift
│   ├── GitCloneBridgeRules.swift
│   ├── PluginGitCloneLocalization.swift
│   └── Resources/Git-Clone.xcstrings
└── Tests/
```

## Dependencies

- `GitCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |

## Features

- **Clone Sheet**: Full-featured clone dialog with URL parsing
- **SSH Authentication**: Built-in SSH help and credential management
- **Destination Picker**: Choose local clone destination folder
- **Repository Name Auto-fill**: Extracts repository name from URL
