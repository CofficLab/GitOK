# GitOK 单体仓库

这是一个使用 pnpm 工作区管理的单体仓库。

## 📦 项目结构

```bash
.
├── packages/          # 共享包和库
├── pnpm-workspace.yaml
└── package.json
```

## 🔧 工作原理

![flow](./static/flow.jpg)

当你在 `/packages/client/` vue 应用目录下开发时，你的更改将被 nodemon 监视，然后重新构建并在 VS Code 扩展主机中打开，随时可以通过 VS Code 命令面板使用！

在这里你可以看到你的 Vue 项目已经构建完成并通过 VS Code webview API 注入。你可以充分利用 Vue 的功能，比如它出色的响应式特性和可用的扩展（如 `vue-router`）！

在 Vue 应用代码中，`vscode` 对象是全局可访问的，可以用来向 VS Code 运行时发送消息并执行诸如读/写文件等任务。

![helloworld](./static/helloworld.gif)

## 📄 技术参考

[使用 Vue 3 和 WebView Panels API 开发 VS Code 扩展](https://medium.com/@mhdi_kr/developing-a-vs-code-extension-using-vue-3-and-webview-panels-api-536d87ce653a)

## VS Code 调试配置说明

本项目包含多个子项目的调试配置，可以通过 VS Code 的调试功能（F5）来启动调试。


## 🔗 链接

- [GitHub](https://github.com/cofficlab/CodeBuddy)
- [VS Code 市场](https://marketplace.visualstudio.com/items?itemName=coffic.smart-buddy)

## 🤝 贡献

如果你有任何问题或建议，请创建一个新的 issue。如果你开发了任何功能或改进，欢迎提交 pull request！🙏

## 📝 许可证

本项目基于 MIT 许可证开源。
