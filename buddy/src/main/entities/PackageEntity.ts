/**
 * 插件实体类
 * 用于管理插件的所有相关信息，包括基本信息、路径、状态等
 */

import { readPackageJson, hasPackageJson } from '../utils/PackageUtils.js';
import { logger } from '../managers/LogManager.js';
import { SuperPackage, PluginType, ValidationResult } from '@coffic/buddy-types';

const verbose = false;

export class PackageEntity implements SuperPackage {
    path: string;
    name: string;
    description: string;
    version: string;
    author: string;
    main: string;
    validation?: ValidationResult | null;
    type: PluginType;
    packageJson?: SuperPackage;
    id: string;
    license: string;
    keywords: string[];
    repository: string;
    dependencies: Record<string, string>;
    devDependencies: Record<string, string>;
    scripts: Record<string, string>;

    constructor(path: string, packageJson?: SuperPackage) {
        this.path = path;
        this.packageJson = packageJson;
        this.name = packageJson?.name || '';
        this.description = packageJson?.description || '';
        this.version = packageJson?.version || '';
        this.author = packageJson?.author || '';
        this.main = packageJson?.main || '';
        this.type = 'user';
        this.validation = null;
        this.validation = null;
        this.validation = null;
        this.id = packageJson?.name || '';
        this.license = packageJson?.license || '';
        this.keywords = packageJson?.keywords || [];
        this.repository = packageJson?.repository || '';
        this.dependencies = packageJson?.dependencies || {};
        this.devDependencies = packageJson?.devDependencies || {};
        this.scripts = packageJson?.scripts || {};
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
}
