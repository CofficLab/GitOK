# GitOK示例插件 (TypeScript版)

[![English](https://img.shields.io/badge/English-Click-yellow)](README.md)
[![简体中文](https://img.shields.io/badge/中文文档-点击查看-orange)](README-zh.md)

这是一个使用TypeScript开发的GitOK插件示例。通过这个示例，你可以了解如何使用TypeScript创建GitOK插件。

## 功能特点

- 完整的TypeScript类型支持
- 示例动作实现
- 自定义视图示例

## 目录结构

```
.
├── dist/             # 编译后的JavaScript文件
├── src/              # TypeScript源代码
│   ├── index.ts      # 插件主入口
│   └── types.ts      # TypeScript类型定义
├── views/            # HTML视图文件
│   ├── calculator.html
│   └── time.html
├── package.json      # 项目配置
└── tsconfig.json     # TypeScript配置
```

## 开发指南

### 安装依赖

```bash
pnpm install
```

### 开发模式

```bash
pnpm dev
```

### 构建

```bash
pnpm build
```

## 插件功能

这个示例插件提供了三个基本功能：

1. **打招呼** - 显示一个问候消息
2. **当前时间** - 显示当前时间（嵌入式视图）
3. **计算器** - 提供一个简单的计算器（窗口视图）

## 类型定义

插件使用TypeScript接口定义了清晰的类型结构：

- `Plugin` - 插件主接口
- `Action` - 动作定义接口
- `PluginContext` - 插件上下文接口

## 如何使用

1. 克隆仓库
2. 安装依赖：`pnpm install`
3. 构建项目：`pnpm build`
4. 在GitOK应用中加载此插件

## Links 

- [NPM](https://www.npmjs.com/package/@coffic/buddy-example-plugin)

## 许可证

MIT
