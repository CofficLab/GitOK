# PluginOpenRemote

Opens the remote repository URL in the default web browser.

## Overview

This plugin registers with ID `OpenRemote` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginOpenRemote/
├── Package.swift
├── Sources/PluginOpenRemote/
│   ├── OpenRemotePlugin.swift
│   ├── OpenRemoteButton.swift
│   ├── OpenRemoteURLProvider.swift
│   ├── GitOriginRemoteReader.swift
│   └── Resources/OpenRemote.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `ProjectRulesKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
