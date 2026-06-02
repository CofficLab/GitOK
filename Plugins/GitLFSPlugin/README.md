# GitLFSPlugin

Monitors Git Large File Storage (LFS) status with a status bar tile.

## Overview

This plugin registers with ID `GitLFSPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitLFSPlugin/
├── Package.swift
├── Sources/GitLFSPlugin/
│   ├── GitLFSPlugin.swift
│   ├── GitLFSStatusTile.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `GitOKUI`
- `GitCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
