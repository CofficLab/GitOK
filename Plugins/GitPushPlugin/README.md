# GitPushPlugin

Provides a toolbar button to push local commits to the remote repository.

## Overview

This plugin registers with ID `GitPushPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitPushPlugin/
├── Package.swift
├── Sources/GitPushPlugin/
│   ├── GitPushPlugin.swift
│   ├── GitPushButton.swift
│   └── Localizable.xcstrings
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
