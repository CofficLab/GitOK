# PluginOpenGitHubDesktop

Opens the current project in GitHub Desktop.

## Overview

This plugin registers with ID `OpenGitHubDesktop` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginOpenGitHubDesktop/
├── Package.swift
├── Sources/PluginOpenGitHubDesktop/
│   ├── OpenGitHubDesktopPlugin.swift
│   ├── OpenGitHubDesktopButton.swift
│   ├── GitHubDesktopProjectLauncher.swift
│   └── Resources/OpenGitHubDesktop.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
