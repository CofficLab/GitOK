# GitOK Monorepo

This is a monorepo managed with pnpm workspaces.

## 📦 Project Structure

```
.
├── packages/          # Shared packages and libraries
├── components/        # Reusable UI components
├── pnpm-workspace.yaml
└── package.json
```

## 🚀 Getting Started

### Prerequisites

- Node.js >= 18
- pnpm >= 8

### Installation

```bash
# Install dependencies
pnpm install
```

### Development

```bash
# Start development servers for all packages
pnpm dev

# Build all packages
pnpm build

# Run tests across all packages
pnpm test

# Run linting across all packages
pnpm lint
```

## 📝 Scripts

- `pnpm dev`: Start development servers
- `pnpm build`: Build all packages
- `pnpm test`: Run tests
- `pnpm lint`: Run linting
- `pnpm clean`: Clean build artifacts

## 📚 Workspace Structure

- `packages/*`: Shared utilities and business logic
- `components/*`: Reusable UI components 

# Smart Code Buddy

An AI-powered VS Code extension that provides intelligent coding assistance using various AI providers.

## 🚀 How to use

### Install dependencies

```bash
yarn
```

For running project in development mode use

```bash
yarn watch
```

### Configuration

1. Open VS Code settings
2. Configure your preferred AI provider (OpenAI, Anthropic, or Deepseek)
3. Add the corresponding API key for your chosen provider

### Using the Extension

1. Open the command palette (Ctrl/Cmd + Shift + P)
2. Type and select "Open AI Chat Assistant"
3. Start interacting with your AI coding assistant!

### Adding more commands

To add more commands to your extension, edit the `package.json` located in the `/packages/extension` directory, and use the keys in your `extension.ts` file using `vscode.commands.registerCommand` method.

## 🔧 How it works

![flow](./static/flow.jpg)

The project is built with monorepo structure containing two packages. The first one being the client, and the second being the visual studio code extension program.

when you start developing on the `/packages/client/` vue application directory, your changes will be watched using nodemon, then rebuilt and be opened inside vscode extension host ready to be used with vscode command pallet!

Here you can see your vue project already built and injected using vscode webview API. you can utilize the full functionality of vue such as its amazing reactivity and its available additions (like `vue-router`) out of the box!

Inside the vue application code, the `vscode` object is globally accessible and can be used to send messages to the vscode runtime and perform tasks such as read/writing files, etc.

![helloworld](./static/helloworld.gif)

## 🤖 Supported AI Providers

- OpenAI
- Anthropic
- Deepseek

## 📄 Technical Reference

[Developing a VS Code Extension using Vue 3 and WebView Panels API](https://medium.com/@mhdi_kr/developing-a-vs-code-extension-using-vue-3-and-webview-panels-api-536d87ce653a)

## 🔗 Links

- [GitHub](https://github.com/cofficlab/CodeBuddy)
- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=coffic.smart-buddy)

## 🤝 Contribution

If you have any questions or recommendations please create a new issue for it, and if you've hacked together any feature or enhancement, a pull request is more than welcome here! 🙏

## 📝 License

This project is licensed under the MIT License.
