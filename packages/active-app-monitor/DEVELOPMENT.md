# @coffic/active-app-monitor 开发文档

本文档面向想要了解或参与开发的开发者，详细介绍了包的技术实现细节。

## 技术架构

### 整体架构

```mermaid
TypeScript (index.ts)
     ↓
   N-API
     ↓
Objective-C++ (active-app.mm)
     ↓
 macOS APIs (AppKit)
```

### 核心实现原理

1. **原生模块实现**
   - 使用 Objective-C++ 通过 AppKit 框架获取系统前台应用信息
   - 主要使用 `NSWorkspace.sharedWorkspace.frontmostApplication` API
   - 通过 `NSRunningApplication` 获取应用的详细信息

2. **Node.js 绑定**
   - 使用 N-API (Node-API) 实现 Node.js 与原生代码的绑定
   - 确保 ABI 稳定性，支持不同 Node.js 版本
   - 使用 `node-addon-api` 提供的 C++ 包装器简化开发

3. **TypeScript 接口**
   - 提供类型安全的 API
   - 处理错误情况和类型转换
   - 确保 API 的易用性和可靠性

## 构建系统

### node-gyp 配置

`binding.gyp` 文件配置了原生模块的构建过程：

```gyp
{
  "targets": [{
    "target_name": "active-app",
    "sources": [ "active-app.mm" ],
    "include_dirs": [
      "<!@(node -p \"require('node-addon-api').include\")"
    ],
    "defines": [
      "NAPI_DISABLE_CPP_EXCEPTIONS"
    ],
    "conditions": [
      ['OS=="mac"', {
        "xcode_settings": {
          "MACOSX_DEPLOYMENT_TARGET": "10.13",
          "OTHER_CPLUSPLUSFLAGS": ["-std=c++17", "-stdlib=libc++"],
          "OTHER_LDFLAGS": ["-framework CoreGraphics", "-framework AppKit"]
        }
      }]
    ]
  }]
}
```

关键配置说明：

- `target_name`: 生成的原生模块文件名
- `sources`: Objective-C++ 源文件
- `include_dirs`: 包含 node-addon-api 头文件
- `xcode_settings`: macOS 特定的编译器和链接器设置

### 构建流程

1. **TypeScript 编译**

   ```bash
   tsc
   ```

   - 将 TypeScript 代码编译为 JavaScript
   - 输出到 `dist` 目录
   - 生成类型声明文件 (`.d.ts`)

2. **原生模块编译**

   ```bash
   node-gyp rebuild
   ```

   - 根据 `binding.gyp` 配置编译原生模块
   - 输出到 `build/Release` 目录

3. **自动化发布**
   - GitHub Actions 自动触发构建
   - 确保在 macOS 环境下编译
   - 自动升级版本号并发布

## 开发指南

### 环境设置

1. **必需工具**
   - Xcode Command Line Tools
   - Node.js 14+
   - Python 相关依赖:
     - 如果使用 Python 3.13+，需要安装 setuptools：`brew install python-setuptools`
     - 或者使用 Python 3.11：`brew install python@3.11`
     - 这是因为 Python 3.13 移除了 node-gyp 所需的 distutils 模块

2. **推荐的 VSCode 配置**

   ```json
   {
     "clangd.path": "/usr/local/opt/llvm/bin/clangd",
     "clangd.arguments": [
       "--background-index",
       "--clang-tidy",
       "--header-insertion=iwyu"
     ]
   }
   ```

### 调试技巧

1. **原生模块调试**
   - 使用 Xcode 调试 `.mm` 文件
   - 使用 `console.log` 在 JavaScript 层打印信息
   - 使用 `lldb` 调试原生崩溃

2. **常见问题排查**
   - 编译错误：检查 Xcode 和编译器版本
   - 运行时错误：检查 ABI 兼容性
   - 内存泄漏：使用 Instruments 分析

### 性能优化

1. **原生层优化**
   - 最小化 Objective-C 运行时调用
   - 使用缓存避免重复查询
   - 正确处理内存管理

2. **JavaScript 层优化**
   - 减少跨语言边界调用
   - 使用类型化数组传递数据
   - 避免不必要的对象创建

## 测试

### 单元测试

```typescript
// 示例测试用例
describe('getFrontmostApplication', () => {
  it('should return active application info', () => {
    const app = getFrontmostApplication();
    expect(app).toHaveProperty('name');
    expect(app).toHaveProperty('bundleId');
  });
});
```

### 集成测试

- 在不同 Node.js 版本下测试
- 在不同 macOS 版本下测试
- 测试边界情况和错误处理

## 发布流程

1. **版本管理**
   - 遵循语义化版本
   - 自动更新 patch 版本
   - 手动更新 minor 和 major 版本

2. **发布检查清单**
   - TypeScript 编译无错误
   - 原生模块编译成功
   - 测试用例通过
   - 文档更新
   - CHANGELOG 更新

3. **自动化发布**
   - GitHub Actions 自动构建
   - 创建 Release 和标签
   - 发布到 npm

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 确保测试通过
5. 提交 Pull Request

## 注意事项

1. **ABI 兼容性**
   - 使用 N-API 确保兼容性
   - 测试不同 Node.js 版本

2. **macOS 兼容性**
   - 最低支持 macOS 10.13
   - 测试不同 macOS 版本

3. **安全考虑**
   - 避免内存泄漏
   - 正确处理权限
   - 防止缓冲区溢出

## 常见问题（FAQ）

### Q1: 包发布和安装的流程是怎样的？

**发布流程**：

1. 开发者推送代码到 main 分支
2. GitHub Actions 在 macOS 环境下自动构建：
   - 编译 TypeScript 代码到 `dist/`
   - 编译原生模块到 `build/Release/`
3. 构建成功后，将以下文件发布到 npm：

   ```tree
   @coffic/active-app-monitor
   ├── dist/               # 编译好的 JavaScript 代码
   ├── build/Release/      # 编译好的原生模块
   │   └── active-app.node
   └── README.md          # 使用文档
   ```

**安装流程**：

1. 用户执行 `npm install @coffic/active-app-monitor`
2. npm 直接下载预编译好的文件
3. 用户无需任何编译步骤，可直接使用

### Q2: 为什么不需要在用户环境编译原生模块？

1. **预编译策略**：
   - 包在发布时就在 macOS 环境下完成了编译
   - 用户安装时直接获取编译好的 `.node` 文件
   - 这种方式称为 "预编译二进制分发"

2. **用户环境要求**：
   - 用户不需要安装 Xcode
   - 不需要安装 node-gyp
   - 不需要任何编译工具
   - 只需要运行在 macOS 系统上

### Q3: 如何处理不同 Node.js 版本的兼容性？

1. **N-API 保证**：
   - 使用 N-API (Node-API) 构建原生模块
   - N-API 提供 ABI 稳定性保证
   - 同一个二进制文件可以在不同 Node.js 版本上运行

2. **版本支持**：
   - 支持 Node.js 14.0.0 及以上版本
   - 不需要为每个 Node.js 版本单独编译
   - 自动适配不同的 Node.js 小版本

### Q4: 开发时如何进行本地测试？

1. **本地构建**：

   ```bash
   # 在 packages/active-app-monitor 目录下
   pnpm install    # 安装依赖
   pnpm run build  # 构建包
   ```

2. **本地链接测试**：

   ```bash
   # 在包目录下
   npm link
   
   # 在测试项目中
   npm link @coffic/active-app-monitor
   ```

3. **验证安装**：

   ```typescript
   import { getFrontmostApplication } from '@coffic/active-app-monitor';
   console.log(getFrontmostApplication());
   ```

### Q5: 如何排查安装或运行时问题？

1. **安装问题**：
   - 确认系统是否为 macOS
   - 检查 Node.js 版本是否 ≥ 14.0.0
   - 确认包版本是否最新

2. **运行问题**：
   - 检查 `build/Release/active-app.node` 是否存在
   - 确认进程有足够的系统权限
   - 查看 Node.js 错误堆栈信息

3. **调试方法**：

   ```typescript
   // 开启详细日志
   process.env.DEBUG = 'active-app-monitor:*';
   import { getFrontmostApplication } from '@coffic/active-app-monitor';
   ```

### Q6: 为什么选择在 GitHub Actions 中构建？

1. **环境一致性**：
   - 使用固定的 macOS 环境
   - 确保编译工具链版本一致
   - 避免开发者环境差异

2. **自动化优势**：
   - 自动触发构建和测试
   - 自动版本管理
   - 自动发布流程

3. **质量保证**：
   - 每次发布都在干净的环境中构建
   - 运行完整的测试套件
   - 保证二进制兼容性

### Q7: 为什么构建时会遇到 Python distutils 相关错误？

1. **问题原因**：
   - node-gyp 依赖 Python 的 distutils 模块来构建原生模块
   - Python 3.13 及以上版本移除了 distutils 模块
   - 这会导致构建过程失败，报错：`ModuleNotFoundError: No module named 'distutils'`

2. **解决方案**：
   - 方案一：安装 setuptools（推荐）

     ```bash
     brew install python-setuptools
     ```

   - 方案二：使用较低版本的 Python

     ```bash
     brew install python@3.11
     ```

3. **为什么会有这个问题**：
   - node-gyp 是用来编译 Node.js 原生模块的工具
   - 它使用 Python 来生成跨平台的构建文件
   - 这是历史原因造成的，因为最初 Node.js 基于 Google 的 V8 引擎，而 V8 使用 Python 作为构建工具

### Q8: 为什么选择在 GitHub Actions 中构建？

1. **环境一致性**：
   - 使用固定的 macOS 环境
   - 确保编译工具链版本一致
   - 避免开发者环境差异

2. **自动化优势**：
   - 自动触发构建和测试
   - 自动版本管理
   - 自动发布流程

3. **质量保证**：
   - 每次发布都在干净的环境中构建
   - 运行完整的测试套件
   - 保证二进制兼容性
