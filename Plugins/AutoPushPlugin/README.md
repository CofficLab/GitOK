# AutoPushPlugin

Automatically pushes commits to the remote repository on a configurable schedule.

## Overview

This plugin registers with ID `AutoPushPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
AutoPushPlugin/
├── Package.swift
├── Sources/AutoPushPlugin/
│   ├── AutoPushPlugin.swift
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

- `GitOKCoreKit`
- `GitCoreKit`
- `ProjectRulesKit`
- `ProjectSupportKit`

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
