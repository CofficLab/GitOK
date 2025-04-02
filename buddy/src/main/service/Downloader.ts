/**
 * 包下载数据库
 * 负责处理 npm 包的下载和解压
 */
import * as fs from 'fs';
import * as path from 'path';
import * as tar from 'tar';
import { logger } from '../managers/LogManager';
import axios from 'axios';
import { npmRegistryService } from './NpmRegistryService';

export class Downloader {
  private static instance: Downloader;

  private constructor() { }

  public static getInstance(): Downloader {
    if (!Downloader.instance) {
      Downloader.instance = new Downloader();
    }
    return Downloader.instance;
  }

  /**
   * 从URL下载文件到指定路径
   * @param url 下载地址
   * @param destPath 目标路径
   */
  public async downloadFile(url: string, destPath: string): Promise<void> {
    return new Promise(async (resolve, reject) => {
      logger.info(`开始下载文件`, {
        url,
        destPath,
      });

      // 确保目标目录存在
      const destDir = path.dirname(destPath);
      if (!fs.existsSync(destDir)) {
        logger.info(`创建目标目录: ${destDir}`);
        fs.mkdirSync(destDir, { recursive: true });
      }

      const file = fs.createWriteStream(destPath);

      try {
        const response = await axios({
          method: 'get',
          url: url,
          responseType: 'stream',
          maxRedirects: 5,
        });

        if (response.status !== 200) {
          const errorMsg = `下载失败，状态码: ${response.status}`;
          logger.error(errorMsg, {
            url,
            destPath,
            statusCode: response.status,
          });
          reject(new Error(errorMsg));
          return;
        }

        response.data.pipe(file);

        file.on('finish', () => {
          file.close();
          logger.info(`文件下载完成`, {
            url,
            destPath,
            size: fs.statSync(destPath).size,
          });
          resolve();
        });
      } catch (err) {
        fs.unlink(destPath, () => { }); // 清理部分下载的文件
        const errorMsg = `下载请求失败: ${err instanceof Error ? err.message : String(err)}`;
        logger.error(errorMsg, {
          url,
          destPath,
          error: err,
        });
        reject(new Error(errorMsg));
      }

      file.on('error', (err) => {
        fs.unlink(destPath, () => { }); // 清理部分下载的文件
        const errorMsg = `文件写入失败: ${err.message}`;
        logger.error(errorMsg, {
          url,
          destPath,
          error: err,
        });
        reject(new Error(errorMsg));
      });
    });
  }

  /**
   * 解压 tar.gz 文件
   * @param tarPath tar文件路径
   * @param extractPath 解压目标路径
   */
  public async extractTarball(
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
   * 下载并解压NPM包到指定目录
   * @param packageName NPM包名
   * @param destinationDir 目标目录
   */
  public async downloadAndExtractPackage(
    packageName: string,
    destinationDir: string
  ): Promise<void> {
    // 1. 获取包的元数据
    const encodedPackageName = encodeURIComponent(packageName).replace(
      /%40/g,
      '@'
    );
    logger.info(`准备获取包元数据`, {
      packageName,
      encodedName: encodedPackageName,
      destinationDir,
    });

    const metadata = await npmRegistryService.fetchPackageMetadata(encodedPackageName);

    // 2. 获取最新版本和下载地址
    const latestVersion = metadata['dist-tags'].latest;
    const tarballUrl = metadata.versions?.[latestVersion]?.dist?.tarball;
    if (!tarballUrl) {
      throw new Error(`无法获取包 ${packageName} 版本 ${latestVersion} 的下载地址`);
    }

    logger.info(`获取到包信息`, {
      packageName,
      version: latestVersion,
      tarballUrl,
    });

    // 确保目标目录存在
    if (!fs.existsSync(destinationDir)) {
      fs.mkdirSync(destinationDir, { recursive: true });
    }

    // 3. 下载tar包
    const safePackageName = packageName.replace(/[@/]/g, '-');
    const tempTarPath = path.join(destinationDir, `${safePackageName}.tgz`);
    await this.downloadFile(tarballUrl, tempTarPath);

    // 4. 解压tar包到临时目录
    const tempDir = path.join(destinationDir, 'temp');
    if (fs.existsSync(tempDir)) {
      // 清理旧的临时目录
      fs.rmdirSync(tempDir, { recursive: true });
    }
    fs.mkdirSync(tempDir, { recursive: true });

    logger.info(`解压tar包到: ${tempDir}`);
    await this.extractTarball(tempTarPath, tempDir);

    // 5. 移动文件到插件目录
    const files = fs.readdirSync(tempDir);
    for (const file of files) {
      const srcPath = path.join(tempDir, file);
      const destPath = path.join(destinationDir, file);

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
  }
}

// 导出单例
export const packageDownloaderDB = Downloader.getInstance();
