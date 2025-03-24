# @coffic/active-app-monitor

macOS 系统活跃应用监听器。

## 功能

- 获取当前活跃的应用信息（名称、Bundle ID等）
- 纯 Native 实现，性能优异
- 使用 Node.js N-API，ABI 稳定性好

## 安装

```bash
npm install @coffic/active-app-monitor
# 或者
yarn add @coffic/active-app-monitor
# 或者
pnpm add @coffic/active-app-monitor
```

## 使用

```typescript
import { getFrontmostApplication } from '@coffic/active-app-monitor';

// 获取当前活跃的应用信息
const app = getFrontmostApplication();
console.log(app);
// 输出: { name: 'Visual Studio Code', bundleId: 'com.microsoft.VSCode' }
```

## 目录结构

```tree
.
├── src/                  # TypeScript 源代码
│   └── index.ts         # 主入口文件
├── native/              # 原生模块源代码
│   ├── active-app.mm    # Objective-C++ 实现文件
│   ├── binding.gyp      # node-gyp 构建配置
│   └── build.js         # 构建脚本
├── build/               # 编译产物目录
│   └── Release/         # Release 版本的编译产物
│       └── active-app.node  # 编译后的原生模块
├── dist/                # TypeScript 编译输出
├── package.json         # 包配置文件
└── README.md           # 说明文档
```

## 开发

1. 克隆仓库并安装依赖：

   ```bash
   git clone <repository-url>
   cd active-app-monitor
   pnpm install
   ```

2. 构建项目：

   ```bash
   pnpm run build
   ```

   这将执行以下操作：
   - 编译 TypeScript 代码到 `dist` 目录
   - 编译原生模块到 `build/Release` 目录

3. 运行测试：

   ```bash
   pnpm test
   ```

## 注意事项

- 仅支持 macOS 系统
- 需要 Node.js 14.0.0 或更高版本
- 编译环境需要安装 Xcode 命令行工具

## 许可证

MIT
