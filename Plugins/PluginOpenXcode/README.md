# PluginOpenXcode

Opens the current project in Xcode.

## Overview

This plugin registers with ID `OpenXcode` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginOpenXcode/
├── Package.swift
├── Sources/PluginOpenXcode/
│   ├── OpenXcodePlugin.swift
│   ├── OpenXcodeButton.swift
│   ├── XcodeProjectLauncher.swift
│   └── Resources/OpenXcode.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
