import { BaseIDEService } from './base';
import { VSCodeService } from './vscode';
import { CursorService } from './cursor';
import { TraeService } from './trae';
import { FileSystemHelper } from '../utils/file-system-helper';
import { GitHelper } from '../utils/git-helper';
import { Logger } from '../utils/logger';
import fs from 'fs';
import path from 'path';
import os from 'os';

const logger = new Logger('IdeFactory');

interface Workspace {
    name: string;
    path: string;
}

/**
 * IDE服务工厂
 * 用于创建不同IDE的服务实例
 */
export class IDEServiceFactory {
    private static readonly CACHE_DIR = path.join(
        os.homedir(),
        '.coffic',
        'ide-workspace'
    );
    private static readonly CACHE_FILE = path.join(
        IDEServiceFactory.CACHE_DIR,
        'workspace.json'
    );
    private static readonly CURRENT_APP_KEY = '_current_app_';

    /**
     * 清理工作区路径
     * 处理各种特殊格式的路径，使其变为本地文件系统路径
     */
    public static cleanWorkspacePath(workspace: string | null): string | null {
        if (!workspace) return null;

        // 处理vscode-remote开发容器路径
        if (workspace.startsWith('vscode-remote://dev-container+')) {
            try {
                // 打印完整的路径进行调试
                logger.debug(`处理开发容器路径: ${workspace}`);

                // 直接解码整个URI部分(这部分是十六进制编码的字符串)
                const containerUri = workspace.split('vscode-remote://dev-container+')[1].split('/workspaces/')[0];

                // 尝试从十六进制字符串中提取hostPath
                const hexString = containerUri;
                let plainText = '';

                // 每两个字符作为一个十六进制，转换为实际字符
                for (let i = 0; i < hexString.length; i += 2) {
                    const hex = hexString.substring(i, i + 2);
                    plainText += String.fromCharCode(parseInt(hex, 16));
                }

                logger.debug(`解码后的内容: ${plainText}`);

                // 从解码后的文本中提取hostPath
                const hostPathMatch = /"hostPath":"([^"]+)"/.exec(plainText);
                if (hostPathMatch && hostPathMatch[1]) {
                    const hostPath = hostPathMatch[1];
                    logger.debug(`提取到的hostPath: ${hostPath}`);
                    return hostPath;
                }
            } catch (error) {
                logger.error(`解析开发容器路径失败: ${error}`);
            }
        }

        // 其他远程路径格式的处理可以在这里添加
        // 例如: vscode-remote://ssh-remote+user@host/path/to/workspace

        // 去除file://前缀
        let cleanPath = workspace.replace(/^file:\/\//, '');

        // 处理Windows路径中的主机名
        if (process.platform === 'win32' && cleanPath.startsWith('/')) {
            cleanPath = cleanPath.replace(/^\//, '');
        }

        // 处理URL编码
        try {
            cleanPath = decodeURIComponent(cleanPath);
        } catch (e) {
            logger.error('解码工作区路径失败:', e);
        }

        return cleanPath;
    }

    /**
     * 保存当前应用ID到缓存
     * @param appId 应用标识符
     */
    static async saveCurrentApp(appId: string): Promise<void> {
        try {
            // 确保缓存目录存在
            if (!fs.existsSync(this.CACHE_DIR)) {
                fs.mkdirSync(this.CACHE_DIR, { recursive: true });
            }

            // 读取现有缓存
            let cacheData: Record<string, any> = {};
            if (fs.existsSync(this.CACHE_FILE)) {
                const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
                try {
                    cacheData = JSON.parse(content);
                } catch (e) {
                    console.error('解析缓存文件失败，将重新创建', e);
                }
            }

            // 更新当前应用ID
            cacheData[this.CURRENT_APP_KEY] = appId;

            // 写入缓存文件
            fs.writeFileSync(
                this.CACHE_FILE,
                JSON.stringify(cacheData, null, 2),
                'utf8'
            );
        } catch (error) {
            console.error('保存当前应用ID缓存失败:', error);
        }
    }

    /**
     * 获取当前应用ID
     * @returns 当前应用ID，如果不存在则返回空字符串
     */
    static getCurrentApp(): string {
        try {
            if (!fs.existsSync(this.CACHE_FILE)) {
                return '';
            }

            const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
            const cacheData = JSON.parse(content);

            return cacheData[this.CURRENT_APP_KEY] || '';
        } catch (error) {
            console.error('读取当前应用ID缓存失败:', error);
            return '';
        }
    }

    /**
     * 保存工作区信息到缓存
     * @param appId 应用标识符
     * @param workspace 工作区路径
     */
    static async saveWorkspace(
        appId: string,
        workspace: string | null
    ): Promise<void> {
        try {
            // 确保缓存目录存在
            if (!fs.existsSync(this.CACHE_DIR)) {
                fs.mkdirSync(this.CACHE_DIR, { recursive: true });
            }

            // 读取现有缓存
            let cacheData: Record<string, any> = {};
            if (fs.existsSync(this.CACHE_FILE)) {
                const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
                try {
                    cacheData = JSON.parse(content);
                } catch (e) {
                    console.error('解析缓存文件失败，将重新创建', e);
                }
            }

            // 更新缓存
            cacheData[appId] = workspace;

            // 写入缓存文件
            fs.writeFileSync(
                this.CACHE_FILE,
                JSON.stringify(cacheData, null, 2),
                'utf8'
            );
        } catch (error) {
            console.error('保存工作区缓存失败:', error);
        }
    }

    /**
     * 从缓存中获取工作区信息
     * @param appId 应用标识符，如果为空则尝试使用当前缓存的应用ID
     * @returns 工作区路径，如果不存在则返回null
     */
    static getWorkspace(appId?: string): string | null {
        try {
            if (!fs.existsSync(this.CACHE_FILE)) {
                return null;
            }

            const content = fs.readFileSync(this.CACHE_FILE, 'utf8');
            const cacheData = JSON.parse(content);

            // 如果没有提供appId，使用缓存中的当前应用ID
            const actualAppId = appId || cacheData[this.CURRENT_APP_KEY] || '';
            if (!actualAppId) {
                console.error('未提供应用ID且缓存中没有当前应用ID');
                return null;
            }

            // 获取并确保路径格式正确
            const workspace = cacheData[actualAppId] || null;

            // 如果路径存在但不是有效路径，返回null
            if (workspace && !fs.existsSync(workspace)) {
                console.error(`缓存的工作区路径不存在: ${workspace}`);
                return null;
            }

            return workspace;
        } catch (error) {
            console.error('读取工作区缓存失败:', error);
            return null;
        }
    }

    /**
     * 在文件浏览器中打开工作空间
     * @param workspace 工作空间路径
     * @returns 操作结果
     */
    static async openInExplorer(workspace: string): Promise<string> {
        return FileSystemHelper.openInExplorer(workspace);
    }

    /**
     * 检查是否为Git仓库
     * @param workspace 工作空间路径
     * @returns 是否为Git仓库
     */
    static async isGitRepository(workspace: string): Promise<boolean> {
        return GitHelper.isGitRepository(workspace);
    }

    /**
     * 检查是否有未提交的更改
     * @param workspace 工作空间路径
     * @returns 是否有未提交的更改
     */
    static async hasUncommittedChanges(workspace: string): Promise<boolean> {
        return GitHelper.hasUncommittedChanges(workspace);
    }

    /**
     * 获取当前分支名称
     * @param workspace 工作空间路径
     * @returns 当前分支名称
     */
    static async getCurrentBranch(workspace: string): Promise<string> {
        return GitHelper.getCurrentBranch(workspace);
    }

    /**
     * 自动提交并推送Git更改
     * @param workspace 工作空间路径
     * @returns 操作结果
     */
    static async autoCommitAndPush(workspace: string): Promise<string> {
        return GitHelper.autoCommitAndPush(workspace);
    }

    /**
     * 获取Git仓库信息
     * @param workspace 工作空间路径
     * @returns Git仓库信息
     */
    static async getGitInfo(workspace: string): Promise<{
        isRepo: boolean;
        hasChanges?: boolean;
        branch?: string;
        remoteUrl?: string | null;
    }> {
        // 检查是否为Git仓库
        const isRepo = await GitHelper.isGitRepository(workspace);
        if (!isRepo) {
            return { isRepo };
        }

        // 获取Git信息
        const [hasChanges, branch, remoteUrl] = await Promise.all([
            GitHelper.hasUncommittedChanges(workspace),
            GitHelper.getCurrentBranch(workspace),
            GitHelper.getRemoteUrl(workspace)
        ]);

        return {
            isRepo,
            hasChanges,
            branch,
            remoteUrl
        };
    }

    /**
     * 检测所有支持的IDE的工作空间
     * @returns 工作空间列表
     */
    static async detectWorkspaces(): Promise<Workspace[]> {
        logger.info('\n正在检测IDE工作空间...\n');
        const workspaces: Workspace[] = [];

        // 获取所有支持的IDE服务
        const supportedIDEs = ['VSCode', 'Cursor', 'Trae'];

        // 遍历检测每个IDE的工作空间
        for (const ideName of supportedIDEs) {
            const ideService = IDEServiceFactory.createService(ideName);
            if (!ideService) continue;

            try {
                const workspace = await ideService.getWorkspace();

                if (workspace) {
                    workspaces.push({
                        name: ideName,
                        path: workspace // IDE服务已经返回清理过的路径
                    });

                    logger.info(`✅ ${ideName}工作空间: ${workspace}`);
                }
            } catch (err: any) {
                logger.info(`❌ ${ideName}服务出错: ${err.message}`);
            }
        }

        return workspaces;
    }

    /**
     * 创建IDE服务实例
     * @param appId IDE应用ID
     * @returns IDE服务实例
     */
    static createService(appId: string): BaseIDEService | null {
        const lowerAppId = appId.toLowerCase();

        // 根据应用ID创建对应的服务实例
        if (lowerAppId.includes('code') || lowerAppId.includes('vscode')) {
            return new VSCodeService('VSCodeService');
        }

        if (lowerAppId.includes('cursor')) {
            return new CursorService('CursorService');
        }

        if (lowerAppId.includes('trae')) {
            return new TraeService('TraEService');
        }

        return null;
    }
}