# OpenVSCodePlugin

Opens the current project in Visual Studio Code.

## Overview

This plugin registers with ID `OpenVSCode` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenVSCodePlugin/
├── Package.swift
├── Sources/OpenVSCodePlugin/
│   ├── OpenVSCodePlugin.swift
│   ├── OpenVSCodeButton.swift
│   ├── VSCodeProjectLauncher.swift
│   └── Localizable.xcstrings
└── Tests/
```

## Dependencies

- `KitGitOKCore`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
