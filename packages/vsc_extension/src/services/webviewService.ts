import * as vscode from 'vscode';
import * as path from 'path';

/**
 * 创建和配置WebView面板
 */
export function createWebviewPanel(context: vscode.ExtensionContext): vscode.WebviewPanel {
    const panel = vscode.window.createWebviewPanel(
        "vueWebview",
        "AI Chat",
        vscode.ViewColumn.One,
        {
            enableScripts: true,
            localResourceRoots: [
                vscode.Uri.file(
                    path.join(context.extensionPath, "vue-dist", "assets")
                ),
            ],
        }
    );

    const dependencyNameList: string[] = [
        "index.css",
        "index.js",
        "vendor.js",
        "logo.png",
    ];
    const dependencyList: vscode.Uri[] = dependencyNameList.map((item) =>
        panel.webview.asWebviewUri(
            vscode.Uri.file(
                path.join(context.extensionPath, "vue-dist", "assets", item)
            )
        )
    );

    panel.webview.html = getWebviewHtml(dependencyList);
    return panel;
}

/**
 * 生成WebView的HTML内容
 */
function getWebviewHtml(dependencies: vscode.Uri[]): string {
    return `<!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>AI Chat</title>
    <script>
          const vscode = acquireVsCodeApi();
    </script>
    <script type="module" crossorigin src="${dependencies[1]}"></script>
    <link rel="modulepreload" href="${dependencies[2]}">
    <link rel="stylesheet" href="${dependencies[0]}">
  </head>
  <body>
    <div id="app"></div>
  </body>
  </html>`;
} 