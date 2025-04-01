import readline from 'node:readline/promises'
import chalk from 'chalk'
import { MCPClient, Tool } from './client.js'
import { ServerConfig } from './config.js'

export class CLI {
  private client: MCPClient
  private rl: readline.Interface

  constructor(rl: readline.Interface) {
    this.client = new MCPClient()
    this.rl = rl
  }

  async promptForToolArguments(tool: Tool): Promise<Record<string, unknown>> {
    const args: Record<string, unknown> = {}
    const schema = tool.inputSchema.properties ?? {}

    console.log(chalk.yellow(`\n📝 请输入 ${tool.name} 的参数:`))

    for (const [key, prop] of Object.entries<{ type: string }>(schema)) {
      const isRequired = tool.inputSchema.required?.includes(key)
      const prompt = `${key}${isRequired ? ' (必填)' : ' (选填)'}: `
      const value = await this.rl.question(chalk.blue(prompt))

      if (value || isRequired) {
        switch (prop.type) {
          case 'number':
            args[key] = Number(value)
            break
          case 'boolean':
            args[key] = value.toLowerCase() === 'true'
            break
          case 'object':
            try {
              args[key] = JSON.parse(value)
            } catch {
              args[key] = value
            }
            break
          default:
            args[key] = value
        }
      }
    }

    return args
  }

  async start(config: ServerConfig): Promise<void> {
    try {
      await this.client.connectToServer(config)
      await this.chatLoop()
    } finally {
      await this.client.cleanup()
    }
  }

  private async chatLoop(): Promise<void> {
    console.log(chalk.green('\n🎉 MCP 客户端已启动!'))
    console.log(chalk.blue("💬 输入工具编号或输入 'quit' 退出"))

    const tools = this.client.getTools()

    while (true) {
      console.log(chalk.yellow('\n📋 可用工具列表:'))
      tools.forEach((tool, index) => {
        console.log(chalk.blue(`${index + 1}. ${tool.name}`))
      })

      const input = await this.rl.question(
        chalk.yellow('\n🔧 请选择工具 (1-' + tools.length + ") 或输入 'quit' 退出: ")
      )

      if (input.toLowerCase() === 'quit') {
        break
      }

      const toolIndex = parseInt(input) - 1
      if (isNaN(toolIndex) || toolIndex < 0 || toolIndex >= tools.length) {
        console.log(chalk.red('\n❌ 无效的工具选择!'))
        continue
      }

      const selectedTool = tools[toolIndex]
      try {
        const args = await this.promptForToolArguments(selectedTool)
        console.log(chalk.blue('\n🔄 正在执行工具...，args', args))
        await this.client.executeTool(selectedTool.name, args)
      } catch (error) {
        console.error(chalk.red('\n❌ 工具执行失败:'), error)
      }
    }
  }
}
