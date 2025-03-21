import path from "path";
import os from "os";
import fs from "fs";
import chalk from "chalk";
import readline from "readline/promises";

// 默认配置
export const projectDir = path.join(os.homedir(), 'Code', 'Playground', 'build_mcp_for_cursor', 'project');
export const defaultPath = path.join(projectDir, 'main.py');
export const defaultCommand = `uv --directory ${projectDir} run`;

export class ConfigManager {
    private rl: readline.Interface;

    constructor(rl: readline.Interface) {
        this.rl = rl;
    }

    private checkScriptExists(scriptPath: string): boolean {
        if (!fs.existsSync(scriptPath)) {
            console.log(chalk.yellow(`\n💡 提示：找不到服务器脚本：`) + chalk.red(scriptPath));
            console.log(chalk.blue('请检查路径是否正确。\n'));
            return false;
        }
        return true;
    }

    async promptConfig(): Promise<{ scriptPath: string; command: string }> {
        const title = chalk.cyan('\n💡 欢迎使用 MCP 服务！');
        const defaultPathInfo = [
            chalk.blue('\n默认服务器脚本路径：'),
            chalk.yellow(defaultPath),
            chalk.blue('\n默认启动命令：'),
            chalk.yellow(`${defaultCommand} main.py`),
        ].join('\n');

        const options = [
            chalk.yellow('\n\n选项：'),
            chalk.white('1) 使用默认配置 [回车]'),
            chalk.white('2) 自定义配置\n'),
        ].join('\n');

        console.log([title, defaultPathInfo, options].join(''));

        const answer = await this.rl.question(chalk.green('请选择 (1-2): '));
        const choice = answer.trim() || '1';

        switch (choice) {
            case '1':
                return { scriptPath: defaultPath, command: defaultCommand };
            case '2':
                const workDir = await this.rl.question(chalk.blue('\n请输入工作目录路径: '));
                const resolvedWorkDir = path.resolve(process.cwd(), workDir.trim());
                const scriptName = await this.rl.question(chalk.blue('请输入脚本名称 (例如: main.py): '));
                const customCommand = `uv --directory ${resolvedWorkDir} run`;
                const scriptPath = path.join(resolvedWorkDir, scriptName.trim());

                if (!this.checkScriptExists(scriptPath)) {
                    process.exit(1);
                }

                return { scriptPath, command: customCommand };
            default:
                console.log(chalk.yellow('\n❌ 无效的选择！使用默认配置继续...\n'));
                return { scriptPath: defaultPath, command: defaultCommand };
        }
    }

    parseCommandLineArgs(args: string[]): { scriptPath: string; command: string } {
        if (args.length < 3) {
            return { scriptPath: defaultPath, command: defaultCommand };
        }

        const arg = args[2];
        if (arg.includes('--directory')) {
            // 如果包含 --directory，说明提供了完整的 uv 命令
            return { scriptPath: defaultPath, command: arg };
        } else {
            // 如果是普通路径，使用默认命令
            const scriptPath = path.resolve(process.cwd(), arg);
            const workDir = path.dirname(scriptPath);
            const command = `uv --directory ${workDir} run`;
            return { scriptPath, command };
        }
    }
} 