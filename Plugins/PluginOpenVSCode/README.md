# PluginOpenVSCode

Opens the current project in Visual Studio Code.

## Overview

This plugin registers with ID `OpenVSCode` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginOpenVSCode/
├── Package.swift
├── Sources/PluginOpenVSCode/
│   ├── OpenVSCodePlugin.swift
│   ├── OpenVSCodeButton.swift
│   ├── VSCodeProjectLauncher.swift
│   └── Resources/OpenVSCode.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
