# PluginBanner

Creates and manages app store banner images with multiple templates (Classic, Minimal) and export formats.

## Overview

This plugin registers with ID `BannerPlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginBanner/
├── Package.swift
├── Sources/PluginBanner/
│   ├── BannerPlugin.swift
│   ├── BannerProvider.swift
│   ├── BannerDetailLayout.swift
│   ├── BannerEvents.swift
│   ├── TemplateSelector.swift
│   ├── TabBar/BannerBtnAdd.swift
│   ├── TabBar/BannerTab.swift
│   ├── TabBar/BannerTabs.swift
│   ├── Model/BannerFile.swift
│   ├── Model/BannerTemplate.swift
│   ├── Model/BannerTemplateCatalog.swift
│   ├── Model/BannerTemplateDataStore.swift
│   ├── Model/BannerTemplateSelectionRules.swift
│   ├── Model/ProjectImage.swift
│   ├── Renderer/DeviceSelector.swift
│   ├── Repo/BannerRepo.swift
│   ├── Repo/BannerRepositoryIndex.swift
│   ├── Repo/BannerStorageRules.swift
│   ├── Repo/BannerTemplateRepo.swift
│   ├── Tips/EmptyBannerTip.swift
│   ├── Templates/Classic/...
│   ├── Templates/Minimal/...
│   └── Resources/Banner.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `BannerCoreKit`
- `MagicAlert`
- `MagicKit`
- `ProjectRulesKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |

## Features

- **Multiple Templates**: Classic and Minimal banner templates
- **Device Selection**: Choose device frame for rendering
- **Export Formats**: PNG, App Store, and iPhone App Store download options
- **Template Editing**: Modify title, subtitle, features, background, image, and opacity
