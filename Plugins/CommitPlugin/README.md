# CommitPlugin

Full-featured Git commit plugin with commit form, history list, graph view, avatar support, and user configuration.

## Overview

This plugin registers with ID `CommitPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
CommitPlugin/
├── Package.swift
├── Sources/CommitPlugin/
│   ├── CommitPlugin.swift
│   ├── Models/AvatarUser.swift
│   ├── Models/CommitAlertRules.swift
│   ├── Models/CommitCategory.swift
│   ├── Models/CommitGraphPresentationRules.swift
│   ├── Models/CommitHistoryActionRules.swift
│   ├── Models/CommitListPaginationRules.swift
│   ├── Models/CommitMessageRules.swift
│   ├── Models/CommitRemoteSyncRules.swift
│   ├── Models/CommitRowAppearanceRules.swift
│   ├── Models/CommitStyle.swift
│   ├── Models/CommitTagRules.swift
│   ├── Models/CommitUserConfigRules.swift
│   ├── Models/CommitUserPreset.swift
│   ├── Models/GitCommitRepo.swift
│   ├── Services/AvatarService.swift
│   ├── Services/CommitAuthorParser.swift
│   ├── Services/CommitRowLoadRules.swift
│   ├── Views/CommitFormHostView.swift
│   ├── Views/CommitFormLayout.swift
│   ├── Views/CommitGraphView.swift
│   ├── Views/CommitHistoryListView.swift
│   ├── Views/CommitMessageInput.swift
│   ├── Views/CommitSubmitButton.swift
│   ├── Views/WorkingStateContentView.swift
│   └── ...
└── Tests/
```

Localization is provided by this package's `Localizable` table.

## Dependencies

- `GitOKCoreKit`
- `GitCoreKit`
- `ProjectSupportKit`
- `ProjectRulesKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |

## Features

- **Commit Form**: Message input with co-author support and user presets
- **Commit History**: Paginated history list with graph view
- **Avatar Support**: Gravatar-based avatar rendering for commit authors
- **Commit Categories**: Tag commits with custom categories
- **User Configuration**: Manage Git user name/email presets
- **Unpushed Actions**: Push or amend unpushed commits
- **Working State**: View staged/unstaged file summary
