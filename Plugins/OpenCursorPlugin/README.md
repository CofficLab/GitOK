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
│   └── Resources/OpenCursor.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
