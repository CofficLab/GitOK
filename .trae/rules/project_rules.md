# 项目规则

## 项目信息

如果你发现了这些规则，则在较靠前的部分换行输出：🍋 我了解了项目的信息。

- 这是一个工作空间，你在 [pnpm-workspace.yaml](mdc:pnpm-workspace.yaml) 可看到配置
- 使用中文和用户交流，即使用户使用了英文
- 当用户和你讨论方案时，不必完全输出代码，因为用户关心的核心点是如何实现

## 包管理器

- pnpm

## 代码风格

- 文件的顶部写清楚文档，包括这个文件做什么的、要注意什么等
- 关键步骤要写清楚注释
- 注释、文档使用中文
- Vue组件使用Vue3的语法，且script放在template之上
- 写Typescript代码时要多思考，不要出现类型错误
- 在新建文件时，要了解项目的基本目录结构，再决定文件应该放在哪个目录中

## Electron 项目 [package.json](mdc:buddy/package.json)

- 这是一个类似spotlight的应用
- tailwind.config.js 在新版中已经不需要了
- 使用 daisyui 和 tailwindcss 来写样式
- 不要硬编码颜色，因为要支持daisyui的主题切换
- 使用Vue
- 所有图标都放入icons 目录，像 [StoreIcon.vue](mdc:buddy/src/renderer/src/icons/StoreIcon.vue) 那样
- 渲染进程的vue组件放在 [ActionListView.vue](mdc:buddy/src/renderer/src/views/ActionListView.vue) 所在的父目录中
- [electron.vite.config.mts](mdc:buddy/electron.vite.config.mts) 中定义了别名，比如：@，充分利用这个别名

## 导入规则
所有导入语句必须使用`@`符号开头，以确保使用项目中定义的别名路径。这有助于保持代码的一致性和可维护性。

### 示例
```typescript
// 正确
import { SomeComponent } from '@/components/SomeComponent';
import { SomeService } from '@/services/SomeService';

// 错误
import { SomeComponent } from '../components/SomeComponent';
import { SomeService } from '../../services/SomeService';
```

### 规则细节
1. **别名路径**：`@`符号应指向项目根目录，通常通过`tsconfig.json`或`vite.config.ts`中的`alias`配置定义。
2. **相对路径**：避免使用相对路径（如`../`或`./`），除非在极少数情况下无法使用别名路径。
3. **第三方库**：第三方库的导入不受此规则限制，应保持原样。

### 例外情况
- 在配置文件中（如`vite.config.ts`或`tsconfig.json`）可以使用相对路径。
- 在测试文件中，如果测试文件与被测试文件在同一目录下，可以使用相对路径。

### 自动修复
应提供自动修复功能，将相对路径转换为别名路径。