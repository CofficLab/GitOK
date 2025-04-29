# GitOK Sample Plugin (TypeScript Version)

[![English](https://img.shields.io/badge/English-Click-yellow)](README.md)
[![简体中文](https://img.shields.io/badge/中文文档-点击查看-orange)](README-zh.md)

This is a sample GitOK plugin developed using TypeScript. Through this example, you can learn how to create GitOK plugins using TypeScript.

## Features

- Complete TypeScript type support
- Sample action implementations
- Custom view examples

## Directory Structure

```
.
├── dist/             # Compiled JavaScript files
├── src/              # TypeScript source code
│   ├── index.ts      # Plugin main entry
│   └── types.ts      # TypeScript type definitions
├── views/            # HTML view files
│   ├── calculator.html
│   └── time.html
├── package.json      # Project configuration
└── tsconfig.json     # TypeScript configuration
```

## Development Guide

### Install Dependencies

```bash
pnpm install
```

### Development Mode

```bash
pnpm dev
```

### Build

```bash
pnpm build
```

## Plugin Features

This sample plugin provides three basic features:

1. **Greeting** - Display a welcome message
2. **Current Time** - Show current time (embedded view)
3. **Calculator** - Provide a simple calculator (window view)

## Type Definitions

The plugin uses TypeScript interfaces to define clear type structures:

- `Plugin` - Main plugin interface
- `Action` - Action definition interface
- `PluginContext` - Plugin context interface

## How to Use

1. Clone the repository
2. Install dependencies: `pnpm install`
3. Build the project: `pnpm build`
4. Load this plugin in GitOK application

## Links

- [NPM](https://www.npmjs.com/package/@coffic/buddy-example-plugin)

## License

MIT
