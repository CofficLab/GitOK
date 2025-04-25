import { exec } from 'child_process';
import { promisify } from 'util';
import { Logger } from './logger';

const execAsync = promisify(exec);
const logger = new Logger('FileSystemHelper');

/**
 * 文件系统工具类
 * 用于处理文件系统相关的操作
 */
export class FileSystemHelper {
    /**
     * 在系统文件浏览器中打开指定路径
     * @param path 要打开的路径
     * @returns 执行结果消息
     */
    static async openInExplorer(path: string): Promise<string> {
        try {
            let command = '';
            // 根据操作系统选择合适的命令
            if (process.platform === 'darwin') {
                command = `open "${path}"`;
            } else if (process.platform === 'win32') {
                command = `explorer "${path}"`;
            } else if (process.platform === 'linux') {
                command = `xdg-open "${path}"`;
            } else {
                return `不支持的操作系统: ${process.platform}`;
            }

            await execAsync(command);
            return `已在文件浏览器中打开: ${path}`;
        } catch (error: any) {
            logger.error('打开文件浏览器失败:', error);
            throw new Error(`打开文件浏览器失败: ${error.message}`);
        }
    }
} 