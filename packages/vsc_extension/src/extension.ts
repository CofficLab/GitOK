// The module 'vscode' contains the VS Code extensibility API
import * as vscode from "vscode";
import { createWebviewPanel } from "./services/webviewService";
import { setupMessageHandler } from "./services/messageHandler";
import { getDefaultProviderConfig } from "./services/aiService";

/**
 * 扩展激活时调用此方法
 */
export function activate(context: vscode.ExtensionContext) {
    console.log('Extension "vue-3-vscode-webview" is now active!');

    // 注册命令
    let disposable = vscode.commands.registerCommand(
        `buddycoder.open`,
        () => {
            // 显示通知
            vscode.window.showInformationMessage("Opening AI Chat Interface");

            // 创建WebView面板
            const panel = createWebviewPanel(context);

            // 获取默认AI提供商配置
            const { provider, hasApiKey } = getDefaultProviderConfig();

            // 发送配置信息给WebView
            panel.webview.postMessage({
                command: 'setConfig',
                aiProvider: provider,
                hasApiKey
            });

            // 设置消息处理
            setupMessageHandler(panel, context);
        }
    );

    context.subscriptions.push(disposable);
}

/**
 * 扩展停用时调用此方法
 */
export function deactivate() { }