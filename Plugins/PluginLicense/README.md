# PluginLicense

Manages open-source license files (MIT, Apache 2.0, GPL-3.0) with template support and a document viewer.

## Overview

This plugin registers with ID `LicensePlugin` and provides functionality through the GitOK plugin system.

## Architecture

```
PluginLicense/
├── Package.swift
├── Sources/PluginLicense/
│   ├── LicensePlugin.swift
│   ├── LicenseDocument.swift
│   ├── LicenseViewer.swift
│   ├── LicenseStatusIcon.swift
│   ├── LicenseTemplate.swift
│   ├── MITLicense.swift
│   ├── Apache2License.swift
│   ├── GPL3License.swift
│   └── Resources/License.xcstrings
└── Tests/
```

## Dependencies

- `GitOKCoreKit`
- `ProjectSupportKit`

## Configuration

| Property           | Value   |
|-------------------|---------|
| `allowUserToggle`  | `false` |
| `defaultEnabled`   | `true` |
