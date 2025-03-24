# GitOK VSCode 工作区插件

这个插件可以检测当前被覆盖的应用是否是 VSCode，如果是则读取其工作区信息并在动作列表中显示。

## 功能

- 自动检测当前被覆盖的应用是否是 VSCode
- 读取 VSCode 工作区信息
- 支持多个平台（Windows、macOS、Linux）
- 支持多种 VSCode 变体（VSCode、VSCode Insiders、VSCodium）
- 支持两种存储格式（JSON 和 SQLite）

## 构建

```bash
# 安装依赖
pnpm install

# 构建插件
pnpm build
```

构建后的文件位于 `dist` 目录下。

## 使用

将构建后的 `dist` 目录复制到 GitOK 的插件目录中即可。

插件会自动检测当前被覆盖的应用，如果是 VSCode，就会在动作列表中显示当前工作区信息。 