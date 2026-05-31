# PluginOpenTerminal

Opens the current project directory in Terminal.app.

## Overview

This plugin registers with ID `OpenTerminal` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginOpenTerminal/
├── Package.swift
├── Sources/PluginOpenTerminal/
│   ├── OpenTerminalPlugin.swift
│   ├── OpenTerminalButton.swift
│   ├── TerminalLauncher.swift
│   └── Resources/OpenTerminal.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
