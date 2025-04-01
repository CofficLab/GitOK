import { Client } from "@modelcontextprotocol/sdk/client/index.js"
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js"
import type { ServerConfig } from "./config.js"
import chalk from "chalk"
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";
import { Transport } from "@modelcontextprotocol/sdk/shared/transport.js";

// 延迟函数
export const delay = (ms: number) => {
    const startTime = Date.now();
    const interval = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const remaining = ms - elapsed;
        const progress = Math.min(100, (elapsed / ms) * 100).toFixed(1);
        console.log(chalk.gray(`⏳ 延迟进度: ${progress}% (剩余: ${remaining}ms)`));
    }, 1000);

    return new Promise(resolve => {
        setTimeout(() => {
            clearInterval(interval);
            resolve(null);
        }, ms);
    });
};

// 格式化错误信息的辅助函数
export function formatError(error: any): string {
    const errorMessage = error.message || String(error);
    const errorStack = error.stack ? `\n调用栈：${error.stack}` : '';
    return chalk.red(errorMessage) + chalk.gray(errorStack);
}

export interface Tool {
    name: string
    description?: string
    inputSchema: {
        type: "object"
        properties?: Record<string, { type: string }>
        required?: string[]
    }
}

export class MCPClient {
    private mcp: Client
    private transport: Transport | null = null
    private tools: Tool[] = []

    constructor() {
        this.mcp = new Client({ name: "mcp-client-cli", version: "1.0.0" })
    }

    async connectToServer(config: ServerConfig): Promise<void> {
        chalk.cyan("\n🚀 正在启动，command 是：", config.command, "args 是：", config.args)

        try {
            console.log(chalk.cyan(`\n[Client] 🚀 正在启动服务器`))

            if (config.sse) {
                console.log(chalk.gray("\nSSE 模式"))
                console.log(chalk.gray("  SSE:"), chalk.blue(config.sse))

                if (this.transport) {
                    try {
                        await this.mcp.close()
                    } catch (error) {
                        console.log(chalk.yellow("\n⚠️ 清理旧连接时出错:"), error)
                    }
                    this.transport = null
                }

                this.transport = new SSEClientTransport(new URL(config.sse))
            } else {
                console.log(chalk.gray("\nSTDIO 模式"))

                console.log(chalk.gray("\n命令详情:"))
                console.log(chalk.gray("  命令:"), chalk.blue(config.command))
                console.log(chalk.gray("  参数:"), chalk.blue(config.args.join(" ")))

                if (this.transport) {
                    try {
                        await this.mcp.close()
                    } catch (error) {
                        console.log(chalk.yellow("\n⚠️ 清理旧连接时出错:"), error)
                    }
                    this.transport = null
                }

                this.transport = new StdioClientTransport({
                    command: config.command,
                    args: config.args
                })
            }

            console.log(chalk.gray("\n⏳ 等待服务器初始化..."))
            await delay(3000)

            console.log(chalk.gray("🔌 正在连接服务器..."))
            this.mcp.connect(this.transport)

            console.log(chalk.gray("⏳ 等待连接稳定..."))
            await delay(1000)

            console.log(chalk.gray("📋 获取可用工具列表..."))
            const toolsResult = await this.mcp.listTools()
            this.tools = toolsResult.tools as Tool[]

            console.log(chalk.green("\n✅ 已连接到服务器，可用工具如下:"))
            this.tools.forEach((tool, index) => {
                console.log(chalk.blue(`  ${index + 1}. ${tool.name}`))
                console.log(chalk.gray(`     ${tool.description}`))
            })
            return
        } catch (e) {
            const errorMsg = formatError(e)
            console.log(
                chalk.yellow(`\n⚠️ 尝试失败:`),
                "\n" + errorMsg
            )

        }
    }

    async executeTool(
        toolName: string,
        args: Record<string, unknown>
    ): Promise<{ content: unknown }> {
        try {
            const tool = this.tools.find((t) => t.name === toolName)
            if (!tool) {
                throw new Error(`找不到工具: ${toolName}`)
            }

            console.log(chalk.cyan(`\n🔧 正在执行工具: ${tool.name}`))
            console.log(chalk.gray(`参数: ${JSON.stringify(args, null, 2)}`))

            const result = await this.mcp.callTool({
                name: tool.name,
                arguments: args
            })

            console.log(chalk.green("\n✅ 执行结果:"))
            console.log(result.content)
            return { content: result.content }
        } catch (error) {
            console.error(chalk.red("\n❌ 执行工具时出错:"), error)
            throw error
        }
    }

    getTools(): Tool[] {
        return this.tools
    }

    async cleanup(): Promise<void> {
        if (this.transport) {
            await this.mcp.close()
            this.transport = null
        }
    }
}
