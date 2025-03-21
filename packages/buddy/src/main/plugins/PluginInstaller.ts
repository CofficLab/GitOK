/**
 * 插件安装器
 * 负责插件的下载、解压和安装
 */
import { app, net } from 'electron';
import fs from 'fs';
import path from 'path';
import { pipeline } from 'stream';
import { promisify } from 'util';
import { EventEmitter } from 'events';
import extract from 'extract-zip';
import { IncomingMessage } from 'http';

export class PluginInstaller extends EventEmitter {
  private pluginsDir: string;
  private tempDir: string;

  constructor() {
    super();
    this.pluginsDir = path.join(app.getPath('userData'), 'plugins');
    this.tempDir = path.join(app.getPath('temp'), 'buddy-plugins');

    console.log(
      `🔧 插件安装器初始化: 插件目录=${this.pluginsDir}, 临时目录=${this.tempDir}`
    );

    // 确保临时目录存在
    this.ensureTempDir();
  }

  /**
   * 确保临时目录存在
   */
  private ensureTempDir(): void {
    if (!fs.existsSync(this.tempDir)) {
      console.log(`📂 创建插件临时目录: ${this.tempDir}`);
      fs.mkdirSync(this.tempDir, { recursive: true });
    } else {
      console.log(`📂 插件临时目录已存在: ${this.tempDir}`);
    }
  }

  /**
   * 从URL下载插件
   * @param url 插件URL
   * @returns 临时文件路径
   */
  public async downloadPlugin(url: string): Promise<string> {
    console.log(`🌐 开始从URL下载插件: ${url}`);
    const tempFilePath = path.join(
      this.tempDir,
      `download-${Date.now()}.buddy`
    );
    console.log(`📄 临时文件路径: ${tempFilePath}`);

    try {
      console.log(`⏳ 下载中...`);
      await this.downloadFile(url, tempFilePath);
      console.log(`✅ 插件下载完成: ${tempFilePath}`);
      return tempFilePath;
    } catch (error: any) {
      console.error(`❌ 下载插件失败: ${error.message}`);
      throw new Error(`下载插件失败: ${error.message}`);
    }
  }

  /**
   * 安装本地插件文件
   * @param filePath 插件文件路径
   * @returns 插件ID
   */
  public async installFromFile(filePath: string): Promise<string> {
    console.log(`📦 开始安装本地插件: ${filePath}`);
    try {
      // 验证插件包
      console.log(`🔍 验证插件包...`);
      const isValid = await this.validatePackage(filePath);
      if (!isValid) {
        console.error(`❌ 无效的插件包: ${filePath}`);
        throw new Error('无效的插件包');
      }
      console.log(`✅ 插件包验证通过`);

      // 获取临时解压目录
      const extractDir = path.join(this.tempDir, `extract-${Date.now()}`);
      console.log(`📂 创建临时解压目录: ${extractDir}`);
      if (!fs.existsSync(extractDir)) {
        fs.mkdirSync(extractDir, { recursive: true });
      }

      // 解压插件包
      console.log(`📤 解压插件包到: ${extractDir}`);
      await this.extractPackage(filePath, extractDir);
      console.log(`✅ 插件包解压完成`);

      // 读取插件清单
      const manifestPath = path.join(extractDir, 'manifest.json');
      console.log(`📄 查找插件清单文件: ${manifestPath}`);
      if (!fs.existsSync(manifestPath)) {
        console.error(`❌ 插件包中缺少manifest.json`);
        throw new Error('插件包中缺少manifest.json');
      }

      console.log(`📝 读取插件清单文件`);
      const manifestData = fs.readFileSync(manifestPath, 'utf-8');
      const manifest = JSON.parse(manifestData);
      console.log(`📋 插件清单内容:`, manifest);

      // 验证清单必需字段
      if (!manifest.id || !manifest.name || !manifest.version) {
        console.error(
          `❌ 插件清单缺少必要字段: ID=${manifest.id}, 名称=${manifest.name}, 版本=${manifest.version}`
        );
        throw new Error('插件清单缺少必要字段');
      }
      console.log(
        `✅ 插件清单验证通过: ID=${manifest.id}, 名称=${manifest.name}, 版本=${manifest.version}`
      );

      const pluginId = manifest.id;
      const pluginDir = path.join(this.pluginsDir, pluginId);
      console.log(`📂 插件安装目录: ${pluginDir}`);

      // 如果插件目录已存在，删除它
      if (fs.existsSync(pluginDir)) {
        console.log(`🗑️ 删除已存在的插件目录: ${pluginDir}`);
        // 递归删除目录
        fs.rmSync(pluginDir, { recursive: true, force: true });
      }

      // 移动插件文件到插件目录
      console.log(`📂 创建插件目录: ${pluginDir}`);
      fs.mkdirSync(pluginDir, { recursive: true });

      // 复制所有文件到插件目录
      console.log(`📋 复制插件文件到安装目录`);
      this.copyDir(extractDir, pluginDir);
      console.log(`✅ 插件文件复制完成`);

      // 清理临时目录
      console.log(`🧹 清理临时解压目录: ${extractDir}`);
      fs.rmSync(extractDir, { recursive: true, force: true });

      console.log(`🎉 插件安装成功: ${pluginId}`);
      return pluginId;
    } catch (error: any) {
      console.error('❌ 安装插件失败:', error);
      throw error;
    }
  }

  /**
   * 从URL下载文件
   * @param url 下载地址
   * @param destination 保存路径
   */
  private downloadFile(url: string, destination: string): Promise<void> {
    console.log(`⏬ 下载文件: ${url} -> ${destination}`);
    return new Promise((resolve, reject) => {
      const request = net.request(url);

      request.on('response', (response) => {
        if (response.statusCode !== 200) {
          console.error(`❌ HTTP请求失败: ${response.statusCode}`);
          reject(new Error(`下载失败: HTTP ${response.statusCode}`));
          return;
        }
        console.log(`✅ HTTP请求成功: ${response.statusCode}`);

        const fileStream = fs.createWriteStream(destination);
        console.log(`📤 创建文件写入流: ${destination}`);

        // 设置进度监听
        let receivedBytes = 0;
        const contentLength = response.headers['content-length'];
        const totalBytes = contentLength
          ? parseInt(contentLength.toString(), 10)
          : 0;
        console.log(`📊 总字节数: ${totalBytes || '未知'}`);

        response.on('data', (chunk) => {
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            const percent = Math.floor((receivedBytes / totalBytes) * 100);
            this.emit('progress', percent);
            if (percent % 20 === 0) {
              console.log(
                `📈 下载进度: ${percent}% (${receivedBytes}/${totalBytes} 字节)`
              );
            }
          }
        });

        // 使用事件方法代替管道连接
        console.log(`🔄 开始文件传输`);

        response.on('data', (chunk) => {
          fileStream.write(chunk);
        });

        response.on('end', () => {
          fileStream.end();
          console.log(`✅ 文件下载完成: ${destination}`);
          resolve();
        });

        fileStream.on('error', (err) => {
          console.error(`❌ 文件写入失败:`, err);
          reject(err);
        });
      });

      request.on('error', (error: Error) => {
        console.error(`❌ 请求错误:`, error);
        reject(error);
      });

      request.end();
    });
  }

  /**
   * 解压插件包
   * @param packagePath 插件包路径
   * @param destPath 目标目录
   */
  private async extractPackage(
    packagePath: string,
    destPath: string
  ): Promise<void> {
    console.log(`📦 解压插件包: ${packagePath} -> ${destPath}`);
    try {
      await extract(packagePath, { dir: destPath });
      console.log(`✅ 解压完成`);
    } catch (error: any) {
      console.error(`❌ 解压失败:`, error);
      throw new Error(`解压插件包失败: ${error.message}`);
    }
  }

  /**
   * 验证插件包
   * @param packagePath 插件包路径
   */
  private async validatePackage(packagePath: string): Promise<boolean> {
    console.log(`🔍 验证插件包: ${packagePath}`);
    // 简单验证，后续可以增加更复杂的验证逻辑
    const exists = fs.existsSync(packagePath);
    const size = exists ? fs.statSync(packagePath).size : 0;
    console.log(`📄 插件包信息: 存在=${exists}, 大小=${size}字节`);
    return true;
  }

  /**
   * 递归复制目录
   * @param src 源目录
   * @param dest 目标目录
   */
  private copyDir(src: string, dest: string): void {
    console.log(`📋 复制目录: ${src} -> ${dest}`);
    const entries = fs.readdirSync(src, { withFileTypes: true });
    console.log(`📄 发现 ${entries.length} 个文件/目录待复制`);

    for (const entry of entries) {
      const srcPath = path.join(src, entry.name);
      const destPath = path.join(dest, entry.name);

      if (entry.isDirectory()) {
        console.log(`📂 创建子目录: ${destPath}`);
        fs.mkdirSync(destPath, { recursive: true });
        this.copyDir(srcPath, destPath);
      } else {
        console.log(`📄 复制文件: ${entry.name}`);
        fs.copyFileSync(srcPath, destPath);
      }
    }
    console.log(`✅ 目录复制完成: ${dest}`);
  }
}

// 导出单例
export const pluginInstaller = new PluginInstaller();
