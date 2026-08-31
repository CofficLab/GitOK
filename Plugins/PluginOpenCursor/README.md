# OpenCursorPlugin

Opens the current project in Cursor editor.

## Overview

This plugin registers with ID `OpenCursor` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenCursorPlugin/
├── Package.swift
├── Sources/OpenCursorPlugin/
│   ├── OpenCursorPlugin.swift
│   ├── OpenCursorButton.swift
│   ├── CursorProjectLauncher.swift
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
