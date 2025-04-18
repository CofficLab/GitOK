import readline from "node:readline/promises"
import dotenv from "dotenv"
import chalk from "chalk"
import { CLI, ConfigManager } from "./index.js"

// 强制启用颜色输出
process.env.FORCE_COLOR = "1"
chalk.level = 3

dotenv.config()

async function main(): Promise<void> {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    })

    const cli = new CLI(rl)
    const configManager = new ConfigManager(rl)

    try {
        let config = await configManager.promptConfig()

        console.log(chalk.cyan("\n[Test] 🚀 选择的配置的 command 是", config.command))
        console.log(chalk.cyan("[Test] 📂 选择的配置的 args 是", config.args))
        console.log(chalk.cyan("[Test] 📂 选择的配置的 env 是", config.env))
        console.log(chalk.cyan("[Test] 🚀 正在启动 MCP 服务..."))

        await cli.start(config)
    } catch (error) {
        console.error(chalk.red("\n❌ MCP 服务启动失败：\n") + error)
        process.exit(1)
    } finally {
        rl.close()
    }
}

main().catch((error) => {
    console.error(chalk.red("\n❌ 程序执行出错："), error)
    process.exit(1)
})
