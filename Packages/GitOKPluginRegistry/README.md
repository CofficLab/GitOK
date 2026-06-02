# GitOKPluginRegistry

Central plugin registry for GitOK.

## Overview

This package is the only place that knows concrete packaged plugins. The main app depends on this registry package instead of depending on plugin packages directly.

When adding a new plugin package, update:

- `Package.swift`
- `Sources/GitOKPluginRegistry/GeneratedPluginRegistry.swift`

Each plugin's own policy still decides whether it is registered at runtime.
