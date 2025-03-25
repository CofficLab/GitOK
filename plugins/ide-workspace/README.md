# IDE工作空间插件

这是一个GitOK插件，用于显示当前IDE的工作空间信息。目前支持VSCode（包括VSCode Insiders和VSCodium）。

## 功能特点

- 支持检测当前IDE是否为VSCode
- 支持读取VSCode的工作空间信息
- 支持JSON和SQLite格式的存储文件
- 跨平台支持（Windows、macOS、Linux）
- TypeScript编写，提供完整的类型定义

## 项目结构

```
.
├── src/
│   ├── index.ts          # 插件入口文件
│   ├── types/            # 类型定义
│   │   └── index.ts
│   ├── services/         # 服务实现
│   │   └── vscode.ts
│   └── utils/           # 工具函数
│       └── logger.ts
├── dist/                # 编译输出目录
├── package.json
├── tsconfig.json
└── README.md
```

## 安装

```bash
pnpm install
```

## 开发

```bash
# 编译
pnpm build

# 监听模式
pnpm watch

# 运行测试
pnpm test
```

## 使用方法

1. 将插件安装到GitOK的插件目录
2. 当激活的应用是VSCode时，插件会自动显示"显示工作空间"动作
3. 点击动作即可查看当前VSCode的工作空间路径

## 配置项

暂无配置项。

## 未来计划

- [ ] 支持更多IDE（WebStorm、IntelliJ IDEA等）
- [ ] 支持显示多工作空间
- [ ] 支持工作空间历史记录
- [ ] 支持快速切换工作空间

## 许可证

MIT 