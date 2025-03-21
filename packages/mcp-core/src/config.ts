import path from "node:path"
import os from "node:os"
import fs from "node:fs"
import chalk from "chalk"
import readline from "node:readline/promises"
import { fileURLToPath } from "node:url"

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

interface ServerConfig {
    command: string
    args: string[]
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
        const configContent = fs.readFileSync(configPath, "utf-8")
        const config = JSON.parse(configContent)

        // 替换配置中的环境变量
        const replaceEnvVars = (str: string): string => {
            return str.replace(/\${HOME}/g, os.homedir())
        }

        // 递归处理所有字符串值
        const processConfig = (obj: unknown): unknown => {
            if (typeof obj === "string") {
                return replaceEnvVars(obj)
            }
            if (Array.isArray(obj)) {
                return obj.map((item) => processConfig(item))
            }
            if (typeof obj === "object" && obj !== null) {
                const result: Record<string, unknown> = {}
                for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
                    result[key] = processConfig(value)
                }
                return result
            }
            return obj
        }

        return processConfig(config) as ServerConfigs
    } catch (error) {
        console.error(chalk.red("无法加载服务器配置文件："), error)
        return { mcpServers: {} }
    }
}

const serverConfigs = loadServerConfigs()

export class ConfigManager {
    private rl: readline.Interface

    constructor(rl: readline.Interface) {
        this.rl = rl
    }

    private checkScriptExists(scriptPath: string): boolean {
        if (!fs.existsSync(scriptPath)) {
            console.log(chalk.yellow(`\n💡 提示：找不到服务器脚本：`) + chalk.red(scriptPath))
            console.log(chalk.blue("请检查路径是否正确。\n"))
            return false
        }
        return true
    }

    private getServerNames(): string[] {
        return Object.keys(serverConfigs.mcpServers)
    }

    private getServerConfig(name: string): ServerConfig | undefined {
        return serverConfigs.mcpServers[name]
    }

    async promptConfig(): Promise<{ scriptPath: string; command: string }> {
        const title = chalk.cyan("\n💡 欢迎使用 MCP 服务！")

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
                console.log(chalk.yellow("\n❌ 无效的服务器配置！使用默认配置继续...\n"))
                const defaultConfig = this.getServerConfig("default")!
                const scriptPath = path.join(
                    path.dirname(defaultConfig.args[1]),
                    defaultConfig.args[3]
                )
                return {
                    scriptPath,
                    command: `${defaultConfig.command} ${defaultConfig.args.join(" ")}`
                }
            }

            // 特殊处理 filesystem 服务器
            if (serverName === "filesystem") {
                return {
                    scriptPath: config.args[config.args.length - 1], // 使用最后一个参数作为路径
                    command: `${config.command} ${config.args.join(" ")}`
                }
            }

            // 处理标准格式的服务器配置
            const directoryIndex = config.args.indexOf("--directory")
            if (directoryIndex !== -1 && directoryIndex + 1 < config.args.length) {
                const workDir = config.args[directoryIndex + 1]
                const scriptName = config.args[config.args.length - 1]
                const scriptPath = path.join(path.dirname(workDir), scriptName)

                if (!this.checkScriptExists(scriptPath)) {
                    process.exit(1)
                }

                return {
                    scriptPath,
                    command: `${config.command} ${config.args.join(" ")}`
                }
            }

            // 如果没有 --directory 参数，直接使用最后一个参数作为脚本路径
            const scriptPath = config.args[config.args.length - 1]
            return {
                scriptPath,
                command: `${config.command} ${config.args.join(" ")}`
            }
        }

        console.log(chalk.yellow("\n❌ 无效的选择！使用默认配置继续...\n"))
        const defaultConfig = this.getServerConfig("default")!
        const scriptPath = path.join(path.dirname(defaultConfig.args[1]), defaultConfig.args[3])
        return {
            scriptPath,
            command: `${defaultConfig.command} ${defaultConfig.args.join(" ")}`
        }
    }

    parseCommandLineArgs(args: string[]): { scriptPath: string; command: string } {
        if (args.length < 3) {
            const defaultConfig = this.getServerConfig("default")!
            const scriptPath = path.join(path.dirname(defaultConfig.args[1]), defaultConfig.args[3])
            return {
                scriptPath,
                command: `${defaultConfig.command} ${defaultConfig.args.join(" ")}`
            }
        }

        const arg = args[2]
        if (arg.includes("--directory")) {
            // 如果包含 --directory，说明提供了完整的 uv 命令
            return {
                scriptPath: path.join(
                    path.dirname(arg.split("--directory ")[1].split(" ")[0]),
                    args[3] || "main.py"
                ),
                command: arg
            }
        } else {
            // 如果是普通路径，使用默认命令
            const scriptPath = path.resolve(process.cwd(), arg)
            const workDir = path.dirname(scriptPath)
            const command = `uv --directory ${workDir} run`
            return { scriptPath, command }
        }
    }
}
