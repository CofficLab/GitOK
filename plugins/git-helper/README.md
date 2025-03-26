# Git Helper 插件

GitOK 的自动 Git 操作插件，提供工作区 Git 状态监控和自动提交推送功能。

## 功能

- 检测当前 IDE 工作空间是否为 Git 仓库
- 显示 Git 仓库状态（分支、变更文件数等）
- 自动提交并推送变更

## 支持的 IDE

- VSCode
- Cursor

## 使用方法

在 GitOK 中唤起插件列表，当在 VSCode 或 Cursor 中使用时，如果当前工作区是 Git 仓库并且有未提交的更改，将会出现自动提交并推送的选项。

## 安装

1. 将插件复制到 GitOK 的 plugins 目录中
2. 重启 GitOK

## 构建

```bash
npm install
npm run build
```

## 测试

测试获取工作空间和 Git 状态功能：

```bash
npm run test
```

## 依赖项

- simple-git: 用于 Git 操作
- sqlite3: 用于解析 VSCode 工作空间信息 