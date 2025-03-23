# GitOK 示例插件

这是一个用于演示如何开发 GitOK 插件的示例项目。

## 功能

这个示例插件提供了以下功能：

1. **打招呼** - 一个简单的问候动作，展示基本的动作执行方式
2. **当前时间** - 显示当前时间的自定义视图
3. **计算器** - 一个简单的计算器，演示复杂的自定义视图

## 安装

在 GitOK 插件商店中安装本插件后，即可通过搜索框查找和使用本插件提供的功能。

## 开发指南

如果你想开发自己的 GitOK 插件，请参考以下步骤：

1. 创建一个新的 npm 包，包名可以使用 `gitok-your-plugin-name` 格式
2. 在 package.json 中添加 `gitokPlugin` 字段来标识这是一个 GitOK 插件
   ```json
   "gitokPlugin": {
     "id": "your-plugin-id"
   }
   ```
3. 实现以下主要接口：
   - `getActions(keyword)` - 返回插件提供的动作列表
   - `executeAction(action)` - 执行指定的动作
   - `getViewContent(viewPath)` (可选) - 获取自定义视图的HTML内容

更详细的开发指南请参考 GitOK 插件开发文档。
