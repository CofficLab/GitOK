import fs from 'fs';
import path from 'path';
import os from 'os';
import { Logger } from '../utils/logger';
import { BaseIDEService } from './base';
import { IDEServiceFactory } from './ide_factory';

const logger = new Logger('TraeService');

/**
 * Trae工作空间服务
 */
export class TraeService extends BaseIDEService {
    /**
     * 获取Trae的工作空间路径
     */
    async getWorkspace(): Promise<string | null> {
        try {
            const storagePath = await this.findStoragePath();
            if (!storagePath) {
                logger.error('未找到Trae存储文件');
                return null;
            }

            // 根据文件类型选择解析方法
            let workspacePath: string | null = null;
            if (storagePath.endsWith('.json')) {
                workspacePath = await this.parseJsonStorage(storagePath);
            } else if (storagePath.endsWith('.vscdb')) {
                logger.debug(`检测到SQLite数据库文件，但当前环境不支持读取。尝试使用备用方法...`);
                // 在 trae 目录下查找文件信息
                workspacePath = await this.findWorkspaceInTraeFolder();
            }

            // 使用IDEServiceFactory清理路径
            if (workspacePath) {
                return IDEServiceFactory.cleanWorkspacePath(workspacePath);
            }

            return null;
        } catch (error) {
            logger.error('获取Trae工作空间失败:', error);
            return null;
        }
    }

    /**
     * 查找Trae存储文件路径
     */
    async findStoragePath(): Promise<string | null> {
        const home = os.homedir();
        let possiblePaths: string[] = [];

        // 根据操作系统添加可能的路径
        if (process.platform === 'darwin') {
            possiblePaths = [
                path.join(home, 'Library/Application Support/Trae/storage.json'),
                path.join(
                    home,
                    'Library/Application Support/Trae/User/globalStorage/state.vscdb'
                ),
                path.join(
                    home,
                    'Library/Application Support/Trae/User/globalStorage/storage.json'
                ),
                path.join(
                    home,
                    'Library/Application Support/Trae - Insiders/storage.json'
                ),
                path.join(
                    home,
                    'Library/Application Support/Trae - Insiders/User/globalStorage/state.vscdb'
                ),
                path.join(
                    home,
                    'Library/Application Support/Trae - Insiders/User/globalStorage/storage.json'
                ),
            ];
        } else if (process.platform === 'win32') {
            const appData = process.env.APPDATA;
            if (appData) {
                possiblePaths = [
                    path.join(appData, 'Trae/storage.json'),
                    path.join(appData, 'Trae/User/globalStorage/state.vscdb'),
                    path.join(appData, 'Trae/User/globalStorage/storage.json'),
                ];
            }
        } else if (process.platform === 'linux') {
            possiblePaths = [
                path.join(home, '.config/Trae/storage.json'),
                path.join(home, '.config/Trae/User/globalStorage/state.vscdb'),
                path.join(home, '.config/Trae/User/globalStorage/storage.json'),
            ];
        }

        // 返回第一个存在的文件路径
        for (const filePath of possiblePaths) {
            if (fs.existsSync(filePath)) {
                logger.debug(`找到Trae存储文件: ${filePath}`);
                return filePath;
            }
        }

        return null;
    }

    /**
     * 解析JSON格式的存储文件
     */
    private async parseJsonStorage(filePath: string): Promise<string | null> {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const data = JSON.parse(content);
            let workspacePath: string | null = null;

            // 尝试从 openedPathsList 获取
            if (data.openedPathsList?.entries?.[0]?.folderUri) {
                workspacePath = data.openedPathsList.entries[0].folderUri;
            }
            // 尝试从 windowState 获取
            else if (data.windowState?.lastActiveWindow?.folderUri) {
                workspacePath = data.windowState.lastActiveWindow.folderUri;
            }

            if (workspacePath) {
                workspacePath = workspacePath.replace('file://', '');
                return decodeURIComponent(workspacePath);
            }

            return null;
        } catch (error) {
            logger.error('解析JSON存储文件失败:', error);
            return null;
        }
    }

    /**
     * 从Trae文件夹中查找工作区路径
     * 这是一个备用方法，当无法读取SQLite数据库时使用
     */
    private async findWorkspaceInTraeFolder(): Promise<string | null> {
        try {
            const home = os.homedir();
            let workspaceFolders: string[] = [];

            // 根据操作系统确定Trae工作区文件夹可能的位置
            if (process.platform === 'darwin') {
                workspaceFolders = [
                    path.join(home, 'Library/Application Support/Trae/User/workspaceStorage'),
                    path.join(home, 'Library/Application Support/Trae - Insiders/User/workspaceStorage')
                ];
            } else if (process.platform === 'win32') {
                const appData = process.env.APPDATA;
                if (appData) {
                    workspaceFolders = [
                        path.join(appData, 'Trae/User/workspaceStorage')
                    ];
                }
            } else if (process.platform === 'linux') {
                workspaceFolders = [
                    path.join(home, '.config/Trae/User/workspaceStorage')
                ];
            }

            for (const folderPath of workspaceFolders) {
                if (!fs.existsSync(folderPath)) {
                    continue;
                }

                // 获取最近修改的工作区文件夹
                const folders = fs.readdirSync(folderPath);
                if (folders.length === 0) {
                    continue;
                }

                // 按修改时间排序，获取最近修改的
                const sortedFolders = folders
                    .map(folder => {
                        const fullPath = path.join(folderPath, folder);
                        const stat = fs.statSync(fullPath);
                        return {
                            path: fullPath,
                            mtime: stat.mtime
                        };
                    })
                    .sort((a, b) => b.mtime.getTime() - a.mtime.getTime());

                // 检查每个文件夹中的 workspace.json 
                for (const folder of sortedFolders) {
                    const workspaceJsonPath = path.join(folder.path, 'workspace.json');
                    if (fs.existsSync(workspaceJsonPath)) {
                        try {
                            const content = fs.readFileSync(workspaceJsonPath, 'utf8');
                            const data = JSON.parse(content);

                            // 尝试提取工作区文件夹路径
                            if (data.folder) {
                                let workspacePath = data.folder;
                                if (workspacePath.startsWith('file://')) {
                                    workspacePath = workspacePath.replace('file://', '');
                                    // 在 Windows 上需要额外处理
                                    if (process.platform === 'win32') {
                                        workspacePath = workspacePath.replace(/^\//, '');
                                    }
                                }
                                if (fs.existsSync(workspacePath)) {
                                    logger.debug(`[TraeService] Found workspace from workspace.json: ${workspacePath}`);
                                    return workspacePath;
                                }
                            }
                        } catch (err) {
                            logger.debug(`解析工作区文件失败: ${workspaceJsonPath}`, err);
                        }
                    }
                }
            }

            // 如果无法找到工作区，尝试从最近文件夹中猜测
            const recentFolders = await this.findRecentFolders();
            if (recentFolders.length > 0) {
                logger.debug(`[TraeService] Using recent folder as workspace: ${recentFolders[0]}`);
                return recentFolders[0];
            }

            return null;
        } catch (error) {
            logger.error('查找工作区文件夹失败:', error);
            return null;
        }
    }

    /**
     * 查找最近使用的文件夹
     */
    private async findRecentFolders(): Promise<string[]> {
        const home = os.homedir();
        const folders: string[] = [];

        try {
            // 常见的项目文件夹路径
            const commonFolders = [
                path.join(home, 'Documents'),
                path.join(home, 'Projects'),
                path.join(home, 'workspace'),
                path.join(home, 'Code')
            ];

            // 查找是否存在这些文件夹
            for (const folder of commonFolders) {
                if (!fs.existsSync(folder)) {
                    continue;
                }

                // 获取子文件夹
                const items = fs.readdirSync(folder);
                for (const item of items) {
                    const fullPath = path.join(folder, item);
                    if (fs.statSync(fullPath).isDirectory()) {
                        // 检查是否是代码项目（有.git文件夹）
                        if (fs.existsSync(path.join(fullPath, '.git'))) {
                            folders.push(fullPath);
                        }
                    }
                }
            }

            // 按修改时间排序
            return folders.sort((a, b) => {
                try {
                    const statA = fs.statSync(a);
                    const statB = fs.statSync(b);
                    return statB.mtime.getTime() - statA.mtime.getTime();
                } catch (err) {
                    return 0;
                }
            });
        } catch (error) {
            logger.error('查找最近文件夹失败:', error);
            return [];
        }
    }
}