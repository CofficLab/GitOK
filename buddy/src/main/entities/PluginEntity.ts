/**
 * 插件实体类
 * 用于管理插件的所有相关信息，包括基本信息、路径、状态等
 */

import { join } from 'path';
import { readPackageJson, hasPackageJson } from '../utils/PackageUtils.js';
import { logger } from '../managers/LogManager.js';
import { PluginStatus, PluginType, ValidationResult } from '@coffic/buddy-types';
import { SendablePlugin } from '@/types/sendable-plugin.js';
import { PackageJson } from '@/types/package-json.js';
const verbose = false;

/**
 * 插件实体类
 * 实现了 Plugin 接口，提供了额外的状态管理功能
 */
export class PluginEntity implements SendablePlugin {
    // 基本信息
    id: string;
    name: string;
    description: string;
    version: string;
    author: string;
    main: string;
    pagePath?: string;
    hasPage: boolean = false;
    validationError: string | null = null;
    path: string;
    type: PluginType;

    // 状态信息
    status: PluginStatus = 'inactive';
    error?: string;
    isLoaded: boolean = false;
    validation?: ValidationResult;
    isBuddyPlugin: boolean = true; // 是否是Buddy插件

    /**
     * 从目录创建插件实体
     * @param pluginPath 插件目录路径
     * @param type 插件类型
     */
    public static async fromDirectory(
        pluginPath: string,
        type: PluginType
    ): Promise<PluginEntity> {
        if (!(await hasPackageJson(pluginPath))) {
            throw new Error(`插件目录 ${pluginPath} 缺少 package.json`);
        }

        if (verbose) {
            logger.info('读取插件目录', { pluginPath, type });
        }

        const packageJson = await readPackageJson(pluginPath);
        const plugin = new PluginEntity(packageJson, pluginPath, type);

        // 在创建时进行验证
        const validation = plugin.validatePackage(packageJson);
        plugin.setValidation(validation);

        return plugin;
    }

    /**
     * 从NPM包信息创建插件实体
     * @param npmPackage NPM包信息
     * @returns 插件实体
     */
    public static fromPackage(npmPackage: PackageJson, type: PluginType): PluginEntity {
        // 创建插件实体
        const plugin = new PluginEntity(npmPackage, '', type);

        // 使用NPM包中的名称作为显示名称（如果有的话）
        if (npmPackage.name) {
            // 格式化名称，移除作用域前缀和常见插件前缀
            plugin.name = PluginEntity.formatPluginName(npmPackage.name);
        }

        return plugin;
    }

    /**
     * 格式化插件名称为更友好的显示名称
     * @param packageName 包名
     */
    private static formatPluginName(packageName: string): string {
        // 移除作用域前缀 (如 @coffic/)
        let name = packageName.replace(/@[^/]+\//, '');

        // 移除常见插件前缀
        const prefixes = ['plugin-', 'buddy-', 'gitok-'];
        for (const prefix of prefixes) {
            if (name.startsWith(prefix)) {
                name = name.substring(prefix.length);
                break;
            }
        }

        // 转换为标题格式 (每个单词首字母大写)
        return name
            .split('-')
            .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
    }

    /**
     * 构造函数
     * @param pkg package.json 内容
     * @param path 插件路径
     * @param type 插件类型
     */
    constructor(pkg: PackageJson, path: string, type: PluginType) {
        this.id = pkg.name;
        this.name = pkg.name;
        this.description = pkg.description || '';
        this.version = pkg.version || '0.0.0';
        this.author = pkg.author || '';
        this.main = pkg.main || '';
        this.path = path;
        this.type = type;
    }

    /**
     * 获取插件主文件的完整路径
     */
    get mainFilePath(): string {
        return join(this.path, this.main);
    }

    /**
     * 获取插件的 package.json 路径
     */
    get packageJsonPath(): string {
        return join(this.path, 'package.json');
    }

    /**
     * 设置插件状态
     */
    setStatus(status: PluginStatus, error?: string): void {
        this.status = status;
        this.error = error;
    }

    /**
     * 设置插件验证状态
     */
    setValidation(validation: ValidationResult): void {
        this.validation = validation;
    }

    /**
     * 标记插件为已加载
     */
    markAsLoaded(): void {
        this.isLoaded = true;
    }

    /**
     * 获取page属性对应的文件的源代码
     * @returns 插件页面视图路径
     */
    getPageSourceCode(): string {
        return "source code";
    }

    /**
     * 禁用插件
     */
    disable(): void {
        this.status = 'disabled';
    }

    /**
     * 启用插件
     */
    enable(): void {
        if (this.status === 'disabled') {
            this.status = 'inactive';
        }
    }

    /**
     * 验证插件包信息
     * @param pkg package.json 内容
     * @returns 验证结果
     */
    private validatePackage(pkg: PackageJson): ValidationResult {
        const errors: string[] = [];

        // 检查基本字段
        if (!pkg.name) errors.push('缺少插件名称');
        if (!pkg.version) errors.push('缺少插件版本');
        if (!pkg.description) errors.push('缺少插件描述');
        if (!pkg.author) errors.push('缺少作者信息');
        if (!pkg.main) errors.push('缺少入口文件');

        const validation = {
            isValid: errors.length === 0,
            errors,
        };

        // 如果验证失败，设置错误状态
        if (!validation.isValid) {
            this.setStatus('error', `插件验证失败: ${errors.join(', ')} `);
        }

        return validation;
    }

    /**
     * 转换为普通对象
     */
    toJSON() {
        return {
            id: this.id,
            name: this.name,
            description: this.description,
            version: this.version,
            author: this.author,
            main: this.main,
            pagePath: this.pagePath,
            hasPage: this.hasPage,
            path: this.path,
            type: this.type,
            status: this.status,
            error: this.error,
            isLoaded: this.isLoaded,
            validation: this.validation,
        };
    }
}
