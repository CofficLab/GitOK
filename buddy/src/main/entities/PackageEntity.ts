/**
 * 插件实体类
 * 用于管理插件的所有相关信息，包括基本信息、路径、状态等
 */

import { readPackageJson, hasPackageJson } from '../utils/PackageUtils.js';
import { logger } from '../managers/LogManager.js';
import { PluginType, ValidationResult } from '@coffic/buddy-types';
import { PluginEntity } from './PluginEntity.js';
import { PackageJson } from '@/types/package-json.js';
const verbose = false;

export class PackageEntity {
    path: string;
    name: string;
    description: string;
    version: string;
    author: string;
    main: string;
    validation?: ValidationResult | null;
    type: PluginType;
    packageJson?: PackageJson;
    id: string;

    constructor(path: string, packageJson?: PackageJson) {
        this.path = path;
        this.packageJson = packageJson;
        this.name = packageJson?.name || '';
        this.description = packageJson?.description || '';
        this.version = packageJson?.version || '';
        this.author = packageJson?.author || '';
        this.main = packageJson?.main || '';
        this.type = 'user';
        this.validation = null;
        this.id = packageJson?.name || '';
    }

    /**
       * 从目录创建包实体
       * @param pluginPath 插件目录路径
       * @param type 插件类型
       */
    public static async fromDirectory(
        path: string,
        type: PluginType
    ): Promise<PackageEntity> {
        if (!(await hasPackageJson(path))) {
            throw new Error(`目录 ${path} 缺少 package.json`);
        }

        if (verbose) {
            logger.info('读取插件目录', { path, type });
        }

        const packageJson = await readPackageJson(path);
        const packageEntity = new PackageEntity(path, packageJson);

        return packageEntity;
    }

    /**
     * 从NPM包信息创建实体
     * @param npmPackage NPM包信息
     * @returns 实体
     */
    public static fromNpmPackage(npmPackage: PackageJson): PackageEntity {
        const packageEntity = new PackageEntity(npmPackage.name, npmPackage);
        return packageEntity;
    }

    /**
     * 获取插件实体
     * @returns 插件实体
     */
    public getPlugin(): PluginEntity | null {
        if (!this.packageJson) {
            return null;
        }

        return PluginEntity.fromPackage(this.packageJson, this.type);
    }
}
