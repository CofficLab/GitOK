# PluginIcon

Manages project icons with support for app icons, web icons, custom folder icons, and multiple export formats (PNG, ImageSet, Xcode, Favicon).

## Overview

This plugin registers with ID `IconPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginIcon/
├── Package.swift
├── Sources/PluginIcon/
│   ├── IconPlugin.swift
│   ├── IconProvider.swift
│   ├── IconDetailLayout.swift
│   ├── IconWelcomeView.swift
│   ├── AssetView/CategoryList.swift
│   ├── AssetView/IconBox.swift
│   ├── AssetView/IconGrid.swift
│   ├── AssetView/IconTilePreview.swift
│   ├── AssetView/SourceTabs.swift
│   ├── Button/BtnChangeImage.swift
│   ├── Button/BtnDelIcon.swift
│   ├── Button/BtnNewIcon.swift
│   ├── Download/DownloadButton.swift
│   ├── Download/DownloadButtons.swift
│   ├── Download/FaviconDownloadButton.swift
│   ├── Download/ImageSetDownloadButton.swift
│   ├── Download/PNGDownloadButton.swift
│   ├── Download/XcodeDownloadButton.swift
│   ├── FilesTabBar/BtnCreate.swift
│   ├── FilesTabBar/IconList.swift
│   ├── FilesTabBar/IconListActions.swift
│   ├── FilesTabBar/IconTabsBar.swift
│   ├── FilesTabBar/IconTile.swift
│   ├── Model/IconAsset.swift
│   ├── Model/IconData.swift
│   ├── Model/IconRemote.swift
│   ├── Renderer/IconMaker.swift
│   ├── Renderer/IconPreview.swift
│   ├── Renderer/IconRenderer.swift
│   ├── Repo/AppIconRepo.swift
│   ├── Repo/CustomFolderIconRepo.swift
│   ├── Repo/IconFileRules.swift
│   ├── Repo/IconRepo.swift
│   ├── Repo/MagicAssetRepo.swift
│   ├── Repo/ProjectIconRepo.swift
│   ├── Repo/ProjectImagesRepo.swift
│   ├── Repo/WebIconRepo.swift
│   ├── Tips/IconStateView.swift
│   └── Resources/Icon.xcstrings
└── Tests/
```

## Dependencies

- `GitOKPluginKit`
- `MagicAlert`
- `MagicKit`
- `ProjectRulesKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
