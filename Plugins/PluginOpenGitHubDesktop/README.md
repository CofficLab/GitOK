# OpenGitHubDesktopPlugin

Opens the current project in GitHub Desktop.

## Overview

This plugin registers with ID `OpenGitHubDesktop` and provides functionality through the GitOK plugin system.

## Architecture

```
OpenGitHubDesktopPlugin/
├── Package.swift
├── Sources/OpenGitHubDesktopPlugin/
│   ├── OpenGitHubDesktopPlugin.swift
│   ├── OpenGitHubDesktopButton.swift
│   ├── GitHubDesktopProjectLauncher.swift
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
