import fs from 'fs';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import { Logger } from './logger';

const execAsync = promisify(exec);
const logger = new Logger('GitHelper');

/**
 * Git工具类
 * 用于检测Git仓库状态和执行提交操作
 */
export class GitHelper {
    /**
     * 检查路径是否为Git仓库
     * @param workspacePath 工作区路径
     * @returns 是否为Git仓库
     */
    static async isGitRepository(workspacePath: string): Promise<boolean> {
        try {
            const gitDir = path.join(workspacePath, '.git');
            return fs.existsSync(gitDir);
        } catch (error) {
            logger.error('检查Git仓库失败:', error);
            return false;
        }
    }

    /**
     * 检查Git仓库是否有未提交的更改
     * @param workspacePath 工作区路径
     * @returns 是否有未提交的更改
     */
    static async hasUncommittedChanges(workspacePath: string): Promise<boolean> {
        try {
            // 执行git status命令，检查是否有未提交的更改
            const { stdout } = await execAsync('git status --porcelain', {
                cwd: workspacePath,
            });
            return stdout.trim() !== '';
        } catch (error) {
            logger.error('检查未提交更改失败:', error);
            return false;
        }
    }

    /**
     * 获取远程仓库URL
     * @param workspacePath 工作区路径
     * @returns 远程仓库URL或null
     */
    static async getRemoteUrl(workspacePath: string): Promise<string | null> {
        try {
            // 获取远程仓库URL
            const { stdout } = await execAsync('git remote get-url origin', {
                cwd: workspacePath,
            });
            return stdout.trim() || null;
        } catch (error) {
            logger.debug('获取远程仓库URL失败:', error);
            return null;
        }
    }

    /**
     * 获取当前分支名称
     * @param workspacePath 工作区路径
     * @returns 当前分支名称
     */
    static async getCurrentBranch(workspacePath: string): Promise<string> {
        try {
            // 获取当前分支名称
            const { stdout } = await execAsync('git rev-parse --abbrev-ref HEAD', {
                cwd: workspacePath,
            });
            return stdout.trim();
        } catch (error) {
            logger.error('获取当前分支失败:', error);
            return 'unknown';
        }
    }

    /**
     * 提交并推送更改
     * @param workspacePath 工作区路径
     * @param commitMessage 提交消息
     * @returns 提交结果
     */
    static async commitAndPush(workspacePath: string, commitMessage: string): Promise<string> {
        try {
            // 添加所有更改
            await execAsync('git add -A', { cwd: workspacePath });
            logger.info('已添加所有更改');

            // 提交更改
            const { stdout: commitResult } = await execAsync(
                `git commit -m "${commitMessage}"`,
                { cwd: workspacePath }
            );
            logger.info('已提交更改:', commitResult);

            // 获取当前分支
            const currentBranch = await this.getCurrentBranch(workspacePath);

            // 检查是否有远程仓库
            const remoteUrl = await this.getRemoteUrl(workspacePath);
            if (!remoteUrl) {
                return `已提交本地更改，但未找到远程仓库。提交信息: ${commitMessage}`;
            }

            // 推送到远程仓库
            const { stdout: pushResult } = await execAsync(
                `git push origin ${currentBranch}`,
                { cwd: workspacePath }
            );
            logger.info('已推送到远程仓库:', pushResult);

            return `已成功提交并推送更改到${currentBranch}分支。提交信息: ${commitMessage}`;
        } catch (error: any) {
            logger.error('提交推送失败:', error);
            throw new Error(`提交推送失败: ${error.message}`);
        }
    }

    /**
     * 获取变更统计摘要
     * @param workspacePath 工作区路径
     * @returns 变更统计摘要
     */
    static async getChangesSummary(workspacePath: string): Promise<string> {
        try {
            const { stdout: status } = await execAsync('git status --porcelain', {
                cwd: workspacePath,
            });

            const changes = {
                modified: 0,
                added: 0,
                deleted: 0,
                renamed: 0,
            };

            status.split('\n').filter(Boolean).forEach(line => {
                const statusCode = line.slice(0, 2).trim();
                if (statusCode.includes('M')) changes.modified++;
                else if (statusCode.includes('A')) changes.added++;
                else if (statusCode.includes('D')) changes.deleted++;
                else if (statusCode.includes('R')) changes.renamed++;
            });

            return Object.entries(changes)
                .filter(([_, count]) => count > 0)
                .map(([type, count]) => `${count} ${type}`)
                .join(', ');
        } catch (error) {
            logger.error('获取变更统计失败:', error);
            return '未知变更';
        }
    }

    /**
     * 自动提交并推送更改
     * 包含变更检查、生成提交信息、提交和推送的完整流程
     * @param workspacePath 工作区路径
     * @returns 执行结果消息
     */
    static async autoCommitAndPush(workspacePath: string): Promise<string> {
        try {
            // 检查是否有未提交的更改
            const hasChanges = await this.hasUncommittedChanges(workspacePath);
            if (!hasChanges) {
                return '当前没有未提交的更改';
            }

            // 获取变更摘要
            const changeSummary = await this.getChangesSummary(workspacePath);

            // 生成提交信息
            const commitMessage = `${changeSummary}`;

            // 执行提交并推送
            return await this.commitAndPush(workspacePath, commitMessage);
        } catch (error: any) {
            logger.error('自动提交失败:', error);
            throw new Error(`自动提交失败: ${error.message}`);
        }
    }
} 