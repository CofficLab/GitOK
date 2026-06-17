# GitUnpushedStatusPlugin

Displays the number of unpushed commits in the status bar and provides a root view for details.

## Overview

This plugin registers with ID `GitUnpushedStatusPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitUnpushedStatusPlugin/
├── Package.swift
├── Sources/GitUnpushedStatusPlugin/
│   ├── GitUnpushedStatusPlugin.swift
│   ├── UnpushedStatusRootView.swift
│   ├── UnpushedStatusEvents.swift
│   └── Localizable.xcstrings
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
