# OpenXcodePlugin

Opens the current project in Xcode.

## Overview

This plugin registers with ID `OpenXcode` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenXcodePlugin/
├── Package.swift
├── Sources/OpenXcodePlugin/
│   ├── OpenXcodePlugin.swift
│   ├── OpenXcodeButton.swift
│   ├── XcodeProjectLauncher.swift
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
