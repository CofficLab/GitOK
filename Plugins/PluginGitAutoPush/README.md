# GitAutoPushPlugin

Automatically pushes commits to the remote repository on a configurable schedule.

## Overview

This plugin registers with ID `GitAutoPushPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitAutoPushPlugin/
├── Package.swift
├── Sources/GitAutoPushPlugin/
│   ├── GitAutoPushPlugin.swift
│   ├── AutoPushService.swift
│   ├── AutoPushSettingsStore.swift
│   ├── AutoPushConfigView.swift
│   ├── AutoPushConfigHeaderView.swift
│   ├── AutoPushStatusBarView.swift
│   ├── AutoPushStatusIcon.swift
│   ├── ConfigRowView.swift
│   ├── ConfiguredProjectsSectionView.swift
│   ├── CurrentProjectSectionView.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitOKCore`
- `KitGitCore`
- `KitProjectRules`
- `KitProjectSupport`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |

## Features

- **Scheduled Auto-Push**: Configure automatic push intervals per project
- **Status Bar Indicator**: Shows auto-push status with a dedicated icon
- **Project Configuration**: Enable/disable auto-push for individual projects
- **Current Project Section**: Quick toggle for the active project
