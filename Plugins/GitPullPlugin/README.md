# GitPullPlugin

Provides a toolbar button to pull changes from the remote repository.

## Overview

This plugin registers with ID `GitPullPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitPullPlugin/
├── Package.swift
├── Sources/GitPullPlugin/
│   ├── GitPullPlugin.swift
│   ├── GitPullButton.swift
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
