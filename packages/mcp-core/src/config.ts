import path from "node:path"
import fs from "node:fs"
import chalk from "chalk"
import readline from "node:readline/promises"
import { fileURLToPath } from "node:url"

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

export interface ServerConfig {
    sse?: string
    command: string
    args: string[]
    env: Record<string, string>
}

interface ServerConfigs {
    mcpServers: {
        [key: string]: ServerConfig
    }
}

// 加载服务器配置
function loadServerConfigs(): ServerConfigs {
    const configPath = path.join(__dirname, "server-examples.json")

    try {
        if (!fs.existsSync(configPath)) {
            throw new Error(`配置文件 ${configPath} 不存在`);
        }

        const configContent = fs.readFileSync(configPath, 'utf-8');
        const config = JSON.parse(configContent) as ServerConfigs;

        if (!config.mcpServers) {
            throw new Error('配置文件格式错误: 缺少mcpServers字段');
        }

        return config;
    } catch (err) {
        console.error(chalk.red(`❌ 加载配置文件失败: ${(err as Error).message}`));
        process.exit(1);
    }
}

const serverConfigs = loadServerConfigs()

export class ConfigManager {
    private rl: readline.Interface

    constructor(rl: readline.Interface) {
        this.rl = rl
    }

    private getServerNames(): string[] {
        return Object.keys(serverConfigs.mcpServers)
    }

    private getServerConfig(name: string): ServerConfig | undefined {
        return serverConfigs.mcpServers[name]
    }

    async promptConfig(): Promise<ServerConfig> {
        const title = chalk.cyan("\n[Config]💡 欢迎使用 MCP 服务！")

        const serverNames = this.getServerNames()
        const options = [
            chalk.yellow("\n\n选项："),
            ...serverNames.map((name, index) =>
                chalk.white(`${index + 1}) ${name} 服务器${index === 0 ? " [回车]" : ""}`)
            )
        ].join("\n")

        console.log([title, options].join(""))

        const answer = await this.rl.question(chalk.green(`请选择 (1-${serverNames.length}): `))
        const choice = parseInt(answer.trim() || "1")

        if (choice <= serverNames.length && choice > 0) {
            const serverName = serverNames[choice - 1]
            const config = this.getServerConfig(serverName)

            if (!config) {
                console.log(chalk.red("\n❌ 无效的服务器配置！"))
                process.exit(1)
            }

            return config
        } else {
            console.log(chalk.red("\n❌ 无效的选项！"))
            process.exit(1)
        }
    }
}
