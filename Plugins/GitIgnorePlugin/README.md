# GitIgnorePlugin

Manages .gitignore files with template support, syntax highlighting, and organization tools.

## Overview

This plugin registers with ID `GitignorePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitIgnorePlugin/
├── Package.swift
├── Sources/GitIgnorePlugin/
│   ├── GitIgnorePlugin.swift
│   ├── GitIgnoreDocument.swift
│   ├── GitIgnoreOrganizer.swift
│   ├── GitIgnoreStatusIcon.swift
│   ├── GitIgnoreTemplate.swift
│   ├── GitIgnoreViewer.swift
│   └── Resources/GitIgnore.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
