# GitDetailPlugin

Displays detailed Git diff information for commits, including text diffs, image comparisons, and file list views.

## Overview

This plugin registers with ID `GitDetailPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
GitDetailPlugin/
├── Package.swift
├── Sources/GitDetailPlugin/
│   ├── GitDetailPlugin.swift
│   ├── Diff/Diff.swift
│   ├── Diff/DiffBlock.swift
│   ├── GitDetailError.swift
│   ├── Models/FileListRules.swift
│   ├── Models/GitDetailAlertRules.swift
│   ├── Models/GitDetailDiffDisplayRules.swift
│   ├── Models/GitDetailImageDiffMode.swift
│   ├── Models/GitDetailPresentationRules.swift
│   ├── Services/GitDetailPasteboard.swift
│   ├── Views/FileListRootView.swift
│   ├── Views/FileDetailHostView.swift
│   ├── Views/FileDiffContentView.swift
│   ├── Views/ImageDiffContentView.swift
│   ├── Views/ImageComparisonView.swift
│   └── ...
└── Tests/
```

Localization is provided by the `GitOKCoreKit` `GitDetail` table.

## Dependencies

- `GitOKCoreKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |

## Features

- **File List View**: Browse changed files with filtering and section headers
- **Text Diff View**: Syntax-highlighted diff with block navigation
- **Image Comparison**: Side-by-side and overlay image diff modes
- **Binary File Handling**: Placeholder for binary files
- **Batch Actions**: Stage/unstage/reset files in batches
