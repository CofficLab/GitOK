import * as vscode from 'vscode';
import { callAIAPI, checkProviderConfig } from './aiService';

/**
 * 处理来自WebView的消息
 */
export function setupMessageHandler(
    panel: vscode.WebviewPanel,
    context: vscode.ExtensionContext
): vscode.Disposable {
    return panel.webview.onDidReceiveMessage(
        async (message) => {
            switch (message.command) {
                case 'fetchAIResponse':
                    await handleAIRequest(panel, message);
                    break;

                case 'checkProvider':
                    handleProviderCheck(panel, message);
                    break;

                case 'openSettings':
                    handleOpenSettings(message);
                    break;

                default:
                    vscode.window.showInformationMessage(message.message || 'Received message from webview');
            }
        },
        undefined,
        context.subscriptions
    );
}

/**
 * 处理AI请求
 */
async function handleAIRequest(panel: vscode.WebviewPanel, message: any): Promise<void> {
    const requestProvider = message.provider ||
        vscode.workspace.getConfiguration('buddycoder').get('aiProvider') as string;

    // 检查是否有API密钥
    const hasProviderApiKey = checkProviderConfig(requestProvider);

    if (!hasProviderApiKey) {
        panel.webview.postMessage({
            command: 'configurationRequired',
            provider: requestProvider
        });
        return;
    }

    try {
        // 调用AI API
        const response = await callAIAPI(message.prompt, requestProvider);
        panel.webview.postMessage({
            command: 'aiResponse',
            response
        });
    } catch (error) {
        panel.webview.postMessage({
            command: 'error',
            message: error instanceof Error ? error.message : String(error)
        });
    }
}

/**
 * 处理提供商检查
 */
function handleProviderCheck(panel: vscode.WebviewPanel, message: any): void {
    const hasApiKey = checkProviderConfig(message.provider);
    panel.webview.postMessage({
        command: 'providerStatus',
        provider: message.provider,
        hasApiKey
    });
}

/**
 * 处理打开设置
 */
function handleOpenSettings(message: any): void {
    vscode.commands.executeCommand(
        'workbench.action.openSettings',
        `buddycoder.${message.provider}.apiKey`
    );
} 