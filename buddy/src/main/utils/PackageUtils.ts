/**
 * package.json 文件读取和解析工具
 * 提供了读取和解析 package.json 文件的功能
 */

import { PackageJson } from '@/types/package-json.js';
import { promises as fs } from 'fs';
import { join } from 'path';

/**
 * 读取指定路径下的 package.json 文件
 * @param directoryPath 目录路径，将在该目录下查找 package.json
 * @returns Promise<PluginPackage> 解析后的 package.json 数据
 * @throws 如果文件不存在或解析失败会抛出错误
 */
export async function readPackageJson(
    directoryPath: string
): Promise<PackageJson> {
    try {
        const packagePath = join(directoryPath, 'package.json');
        const content = await fs.readFile(packagePath, 'utf8');
        return JSON.parse(content) as PackageJson;
    } catch (error) {
        if (error instanceof Error) {
            throw new Error(`读取 package.json 失败: ${error.message}`);
        }
        throw error;
    }
}

/**
 * 检查指定路径下是否存在 package.json 文件
 * @param directoryPath 目录路径
 * @returns Promise<boolean> 是否存在 package.json 文件
 */
export async function hasPackageJson(directoryPath: string): Promise<boolean> {
    try {
        const packagePath = join(directoryPath, 'package.json');
        await fs.access(packagePath);
        return true;
    } catch {
        return false;
    }
}
