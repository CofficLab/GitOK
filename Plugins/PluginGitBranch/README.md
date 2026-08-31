# GitBranchPlugin

Branch management plugin for listing, creating, switching, and deleting Git branches.

## Overview

This plugin registers with ID `GitBranchPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitBranchPlugin/
├── Package.swift
├── Sources/GitBranchPlugin/
│   ├── GitBranchPlugin.swift
│   ├── BranchManagementView.swift
│   ├── BranchPickerView.swift
│   ├── BranchRowView.swift
│   ├── BranchStatusTile.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitOKCore`
- `KitGitCore`
- `KitProjectRules`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |

## Features

- **Branch List**: View all local and remote branches
- **Branch Switching**: Quickly checkout any branch
- **Branch Creation**: Create new branches from the UI
- **Branch Deletion**: Delete local branches
- **Status Tile**: Shows current branch in the status bar
