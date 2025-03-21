import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import chalk from "chalk";
import { formatError, delay } from "./utils.js";

export interface Tool {
    name: string;
    description?: string;
    inputSchema: {
        type: "object";
        properties?: Record<string, { type: string }>;
        required?: string[];
    };
}

export class MCPClient {
    private mcp: Client;
    private transport: StdioClientTransport | null = null;
    private tools: Tool[] = [];

    constructor() {
        this.mcp = new Client({ name: "mcp-client-cli", version: "1.0.0" });
    }

    async connectToServer(command: string, retries = 3) {
        for (let attempt = 1; attempt <= retries; attempt++) {
            try {
                console.log(chalk.cyan(`\n🚀 正在启动服务器 (第 ${attempt}/${retries} 次尝试):`), chalk.yellow(command));

                const [cmd, ...args] = command.split(' ').filter(Boolean);
                if (!cmd || args.length === 0) {
                    throw new Error("命令格式无效。请同时提供命令和脚本路径");
                }

                console.log(chalk.gray('\n命令详情:'));
                console.log(chalk.gray('  命令:'), chalk.blue(cmd));
                console.log(chalk.gray('  参数:'), chalk.blue(args.join(' ')));

                if (this.transport) {
                    try {
                        await this.mcp.close();
                    } catch (error) {
                        console.log(chalk.yellow("\n⚠️ 清理旧连接时出错:"), error);
                    }
                    this.transport = null;
                }

                this.transport = new StdioClientTransport({
                    command: cmd,
                    args: args,
                });

                console.log(chalk.gray('\n⏳ 等待服务器初始化...'));
                await delay(1000);

                console.log(chalk.gray('🔌 正在连接服务器...'));
                this.mcp.connect(this.transport);

                console.log(chalk.gray('⏳ 等待连接稳定...'));
                await delay(1000);

                console.log(chalk.gray('📋 获取可用工具列表...'));
                const toolsResult = await this.mcp.listTools();
                this.tools = toolsResult.tools as Tool[];

                console.log(chalk.green("\n✅ 已连接到服务器，可用工具如下:"));
                this.tools.forEach((tool, index) => {
                    console.log(chalk.blue(`  ${index + 1}. ${tool.name}`));
                    console.log(chalk.gray(`     ${tool.description}`));
                });
                return;
            } catch (e) {
                const errorMsg = formatError(e);
                console.log(chalk.yellow(`\n⚠️ 第 ${attempt}/${retries} 次尝试失败:`), "\n" + errorMsg);

                if (attempt === retries) {
                    console.log(chalk.red("\n❌ 多次尝试后仍无法连接到服务器"));
                    throw e;
                }

                if (this.transport) {
                    try {
                        await this.mcp.close();
                    } catch (closeError) {
                        console.log(chalk.yellow("\n⚠️ 清理连接时出错:"), closeError);
                    }
                    this.transport = null;
                }

                console.log(chalk.blue(`\n🔄 等待 2 秒后重试...`));
                await delay(2000);
            }
        }
    }

    async executeTool(toolName: string, args: any) {
        try {
            const tool = this.tools.find(t => t.name === toolName);
            if (!tool) {
                throw new Error(`找不到工具: ${toolName}`);
            }

            console.log(chalk.cyan(`\n🔧 正在执行工具: ${tool.name}`));
            console.log(chalk.gray(`参数: ${JSON.stringify(args, null, 2)}`));

            const result = await this.mcp.callTool({
                name: tool.name,
                arguments: args,
            });

            console.log(chalk.green('\n✅ 执行结果:'));
            console.log(result.content);
            return result;
        } catch (error) {
            console.error(chalk.red('\n❌ 执行工具时出错:'), error);
            throw error;
        }
    }

    getTools(): Tool[] {
        return this.tools;
    }

    async cleanup() {
        if (this.transport) {
            await this.mcp.close();
            this.transport = null;
        }
    }
} 