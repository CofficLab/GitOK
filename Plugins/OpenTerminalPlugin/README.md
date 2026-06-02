# OpenTerminalPlugin

Opens the current project directory in Terminal.app.

## Overview

This plugin registers with ID `OpenTerminal` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenTerminalPlugin/
├── Package.swift
├── Sources/OpenTerminalPlugin/
│   ├── OpenTerminalPlugin.swift
│   ├── OpenTerminalButton.swift
│   ├── TerminalLauncher.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
