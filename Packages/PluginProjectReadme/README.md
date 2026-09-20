# PluginProjectReadme

A standalone application plugin that implements `ProviderProjectReadme` to find and render a Markdown README from a project's root directory. `PluginWorktreeClean` consumes only the provider contract and places the rendered view at the bottom of its clean-worktree screen.

The renderer recognizes `README.md`, `README.markdown`, and `README.mdown`, including case variations. It stays hidden when the project has no readable README.

## Build

```bash
swift build
```
