# FileInfoPlugin

Displays file path information in the status bar with smart path presentation.

## Overview

This plugin registers with ID `SmartFilePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
FileInfoPlugin/
├── Package.swift
├── Sources/FileInfoPlugin/
│   ├── FileInfoPlugin.swift
│   ├── FileInfoPathPresentation.swift
│   ├── FileInfoTile.swift
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
