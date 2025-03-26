/**
 * 插件商店控制器
 * 负责处理与插件商店相关的业务逻辑
 */
import { shell } from 'electron';
import { IpcResponse } from '@/types/ipc';
import { SuperPlugin } from '@/types/super_plugin';
import { pluginManager } from '../managers/PluginManager';
import { logger } from '../managers/LogManager';
import { pluginDB } from '../db/PluginDB';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as http from 'http';
import * as tar from 'tar';
import { URL } from 'url';

export class PluginStoreController {
  private static instance: PluginStoreController;

  // NPM registry URL
  private readonly NPM_REGISTRY = 'https://registry.npmjs.org';

  // 模拟远程插件列表
  private remotePlugins: SuperPlugin[] = [
    {
      id: '@coffic/plugin-ide-workspace',
      name: 'IDE工作空间',
      version: '1.0.0',
      description: '显示当前IDE的工作空间信息',
      author: 'Coffic Lab',
      type: 'remote',
      path: '',
      npmPackage: '@coffic/plugin-ide-workspace',
    },
    {
      id: '@coffic/buddy-example-plugin',
      name: '示例插件',
      version: '1.0.0',
      description: '示例插件',
      author: 'Coffic Lab',
      type: 'remote',
      path: '',
      npmPackage: '@coffic/buddy-example-plugin',
    },
  ];

  private constructor() {}

  public static getInstance(): PluginStoreController {
    if (!PluginStoreController.instance) {
      PluginStoreController.instance = new PluginStoreController();
    }
    return PluginStoreController.instance;
  }

  /**
   * 获取插件商店列表
   */
  public async getStorePlugins(): Promise<IpcResponse<SuperPlugin[]>> {
    try {
      const plugins = await pluginDB.getAllPlugins();
      return { success: true, data: plugins };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取插件列表失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 获取远程插件列表
   * 目前返回模拟数据，实际应用中应从远程服务器获取
   */
  public getRemotePlugins(): IpcResponse<SuperPlugin[]> {
    try {
      // 实际应用中，这里应该是向远程服务器请求数据
      return { success: true, data: this.remotePlugins };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取远程插件列表失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 从npm registry获取包的元数据
   * @param packageName NPM包名
   */
  private async fetchPackageMetadata(packageName: string): Promise<any> {
    return new Promise((resolve, reject) => {
      const url = `${this.NPM_REGISTRY}/${packageName}`;
      logger.info(`请求NPM包元数据: ${packageName}`, {
        url,
        registry: this.NPM_REGISTRY,
        packageName,
      });

      https
        .get(url, (res) => {
          let data = '';

          res.on('data', (chunk) => {
            data += chunk;
          });

          res.on('end', () => {
            if (res.statusCode === 200) {
              try {
                const metadata = JSON.parse(data);
                logger.info(`成功获取包元数据: ${packageName}`, {
                  url,
                  statusCode: res.statusCode,
                });
                resolve(metadata);
              } catch (err) {
                const errorMsg = `解析元数据失败: ${err instanceof Error ? err.message : String(err)}`;
                logger.error(errorMsg, {
                  url,
                  packageName,
                  error: err,
                });
                reject(new Error(errorMsg));
              }
            } else {
              const errorMsg = `获取元数据失败，状态码: ${res.statusCode}`;
              logger.error(errorMsg, {
                url,
                packageName,
                statusCode: res.statusCode,
                responseBody: data.substring(0, 200), // 只记录前200个字符避免日志过大
              });
              reject(new Error(errorMsg));
            }
          });
        })
        .on('error', (err) => {
          const errorMsg = `请求失败: ${err.message}`;
          logger.error(errorMsg, {
            url,
            packageName,
            error: err,
          });
          reject(new Error(errorMsg));
        });
    });
  }

  /**
   * 从URL下载文件到指定路径
   * @param url 下载地址
   * @param destPath.path 目标路径
   */
  private async downloadFile(url: string, destPath: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const parsedUrl = new URL(url);
      const protocol = parsedUrl.protocol === 'https:' ? https : http;

      logger.info(`开始下载文件`, {
        url,
        destPath,
        protocol: parsedUrl.protocol,
      });

      // 确保目标目录存在
      const destDir = path.dirname(destPath);
      if (!fs.existsSync(destDir)) {
        logger.info(`创建目标目录: ${destDir}`);
        fs.mkdirSync(destDir, { recursive: true });
      }

      const file = fs.createWriteStream(destPath);

      protocol
        .get(url, (response) => {
          if (response.statusCode === 302 || response.statusCode === 301) {
            // 处理重定向
            const redirectUrl = response.headers.location!;
            logger.info(`请求被重定向`, {
              originalUrl: url,
              redirectUrl,
              statusCode: response.statusCode,
            });

            this.downloadFile(redirectUrl, destPath)
              .then(resolve)
              .catch(reject);
            return;
          }

          if (response.statusCode !== 200) {
            const errorMsg = `下载失败，状态码: ${response.statusCode}`;
            logger.error(errorMsg, {
              url,
              destPath,
              statusCode: response.statusCode,
            });
            reject(new Error(errorMsg));
            return;
          }

          response.pipe(file);

          file.on('finish', () => {
            file.close();
            logger.info(`文件下载完成`, {
              url,
              destPath,
              size: fs.statSync(destPath).size,
            });
            resolve();
          });
        })
        .on('error', (err) => {
          fs.unlink(destPath, () => {}); // 清理部分下载的文件
          const errorMsg = `下载请求失败: ${err.message}`;
          logger.error(errorMsg, {
            url,
            destPath,
            error: err,
          });
          reject(err);
        });

      file.on('error', (err) => {
        fs.unlink(destPath, () => {}); // 清理部分下载的文件
        const errorMsg = `文件写入失败: ${err.message}`;
        logger.error(errorMsg, {
          url,
          destPath,
          error: err,
        });
        reject(err);
      });
    });
  }

  /**
   * 解压 tar.gz 文件
   * @param tarPath tar文件路径
   * @param extractPath 解压目标路径
   */
  private async extractTarball(
    tarPath: string,
    extractPath: string
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        tar
          .extract({
            file: tarPath,
            cwd: extractPath,
            strip: 1, // 去掉顶层的package目录
          })
          .then(() => {
            resolve();
          })
          .catch((err) => {
            reject(
              new Error(
                `解压文件失败: ${err instanceof Error ? err.message : String(err)}`
              )
            );
          });
      } catch (err) {
        reject(
          new Error(
            `解压初始化失败: ${err instanceof Error ? err.message : String(err)}`
          )
        );
      }
    });
  }

  /**
   * 下载并安装插件
   * 直接从NPM Registry下载包，不依赖npm命令
   */
  public async downloadPlugin(
    plugin: SuperPlugin
  ): Promise<IpcResponse<boolean>> {
    try {
      if (!plugin.npmPackage) {
        logger.error('下载失败：缺少NPM包名称', { plugin });
        return {
          success: false,
          error: '缺少NPM包名称',
        };
      }

      // 获取用户插件目录
      const directories = pluginDB.getPluginDirectories();
      const userPluginDir = directories.user;

      // 确保目录存在
      if (!fs.existsSync(userPluginDir)) {
        fs.mkdirSync(userPluginDir, { recursive: true });
      }

      // 使用插件ID或干净的包名作为目录名（而不是原始包名）
      // 这样可以避免@scope/name形式的包名导致的路径问题
      const safePluginId = plugin.id.replace(/[@/]/g, '-');

      // 创建插件目录
      const pluginDir = path.join(userPluginDir, safePluginId);
      if (!fs.existsSync(pluginDir)) {
        fs.mkdirSync(pluginDir, { recursive: true });
      }

      logger.info(`开始下载插件`, {
        pluginName: plugin.name,
        pluginId: plugin.id,
        safePluginId,
        npmPackage: plugin.npmPackage,
        pluginDir,
        registry: this.NPM_REGISTRY,
      });

      try {
        // 1. 获取包的元数据
        const encodedPackageName = encodeURIComponent(
          plugin.npmPackage
        ).replace(/%40/g, '@');
        logger.info(`准备获取包元数据`, {
          packageName: plugin.npmPackage,
          encodedName: encodedPackageName,
          url: `${this.NPM_REGISTRY}/${encodedPackageName}`,
        });

        const metadata = await this.fetchPackageMetadata(encodedPackageName);

        // 2. 获取最新版本和下载地址
        const latestVersion = metadata['dist-tags'].latest;
        const tarballUrl = metadata.versions[latestVersion].dist.tarball;

        logger.info(`获取到包信息`, {
          packageName: plugin.npmPackage,
          version: latestVersion,
          tarballUrl,
          shasum: metadata.versions[latestVersion].dist.shasum,
        });

        // 3. 下载tar包
        const tempTarPath = path.join(pluginDir, `${safePluginId}.tgz`);
        await this.downloadFile(tarballUrl, tempTarPath);

        // 4. 解压tar包到临时目录
        const tempDir = path.join(pluginDir, 'temp');
        if (fs.existsSync(tempDir)) {
          // 清理旧的临时目录
          fs.rmdirSync(tempDir, { recursive: true });
        }
        fs.mkdirSync(tempDir, { recursive: true });

        logger.info(`开始解压tar包到: ${tempDir}`);
        await this.extractTarball(tempTarPath, tempDir);
        logger.info(`解压完成`);

        // 5. 移动文件到插件目录
        const files = fs.readdirSync(tempDir);
        for (const file of files) {
          const srcPath = path.join(tempDir, file);
          const destPath = path.join(pluginDir, file);

          // 如果目标文件已存在，先删除
          if (fs.existsSync(destPath)) {
            if (fs.statSync(destPath).isDirectory()) {
              fs.rmdirSync(destPath, { recursive: true });
            } else {
              fs.unlinkSync(destPath);
            }
          }

          // 移动文件或目录
          fs.renameSync(srcPath, destPath);
        }

        // 6. 清理临时文件
        fs.rmdirSync(tempDir, { recursive: true });
        fs.unlinkSync(tempTarPath);

        // 8. 重新扫描插件目录
        await pluginDB.getAllPlugins();

        logger.info(`插件 ${plugin.name} 安装成功`);
        return { success: true, data: true };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        logger.error('下载插件过程中出错', {
          error: errorMessage,
          pluginName: plugin.name,
          pluginId: plugin.id,
          npmPackage: plugin.npmPackage,
        });
        return { success: false, error: errorMessage };
      }
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('下载插件初始化失败', {
        error: errorMessage,
        pluginName: plugin.name,
        pluginId: plugin.id,
        npmPackage: plugin.npmPackage,
      });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 获取插件目录信息
   */
  public getDirectories(): IpcResponse<{ user: string; dev: string }> {
    try {
      const directories = pluginDB.getPluginDirectories();
      return { success: true, data: directories };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取插件目录信息失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 获取已安装的插件列表
   */
  public async getPlugins(): Promise<IpcResponse<SuperPlugin[]>> {
    try {
      const plugins = await pluginManager.getPlugins();
      return { success: true, data: plugins };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('获取插件列表失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 打开插件目录
   */
  public openDirectory(directory: string): IpcResponse<void> {
    try {
      shell.openPath(directory);
      return { success: true, data: undefined };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error('打开插件目录失败', { error: errorMessage });
      return { success: false, error: errorMessage };
    }
  }

  /**
   * 卸载插件
   * @param pluginId 要卸载的插件ID
   */
  public async uninstallPlugin(
    pluginId: string
  ): Promise<IpcResponse<boolean>> {
    try {
      logger.info(`准备卸载插件: ${pluginId}`);

      // 获取插件实例
      const plugin = await pluginDB.find(pluginId);
      if (!plugin) {
        logger.error(`卸载插件失败: 找不到插件 ${pluginId}`);
        return {
          success: false,
          error: `找不到插件: ${pluginId}`,
        };
      }

      // 只允许卸载用户安装的插件，不能卸载开发中的插件
      if (plugin.type !== 'user') {
        logger.error(`卸载插件失败: 无法卸载开发中的插件 ${pluginId}`);
        return {
          success: false,
          error: '无法卸载开发中的插件',
        };
      }

      // 获取插件目录路径
      const pluginPath = plugin.path;
      if (!pluginPath || !fs.existsSync(pluginPath)) {
        logger.error(`卸载插件失败: 插件目录不存在 ${pluginPath}`);
        return {
          success: false,
          error: '插件目录不存在',
        };
      }

      logger.info(`删除插件目录: ${pluginPath}`);

      // 删除插件目录
      fs.rmdirSync(pluginPath, { recursive: true });

      logger.info(`插件 ${pluginId} 卸载成功`);
      return { success: true, data: true };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error(`卸载插件失败: ${errorMessage}`, { pluginId });
      return {
        success: false,
        error: `卸载插件失败: ${errorMessage}`,
      };
    }
  }
}

export const pluginStoreController = PluginStoreController.getInstance();
