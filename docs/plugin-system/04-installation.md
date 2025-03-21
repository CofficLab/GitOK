# 4. 安装机制

Buddy 插件系统实现了不依赖外部 Node.js 环境的插件安装机制，使用户能够轻松安装插件。

## 安装方式

插件可以通过以下方式安装：

1. **从 URL 安装**：用户提供插件包的 URL，系统自动下载并安装
2. **从本地文件安装**：用户选择本地的 `.buddy` 文件进行安装

## 安装流程

1. **获取插件包**
   - 从 URL 下载：使用 Electron 的 `net` 模块下载插件包
   - 从本地加载：读取本地文件

2. **验证插件包**
   - 检查文件格式和完整性
   - 验证插件清单（manifest.json）
   - 检查签名（如果启用）

3. **提取插件**
   - 解压插件包到用户数据目录的插件文件夹
   - 目标路径：`{userData}/plugins/{pluginId}/`

4. **注册插件**
   - 向插件注册表添加插件信息
   - 存储元数据、版本和安装时间

## 实现细节

### 1. 下载机制

```typescript
/**
 * 从URL下载文件
 * @param url 下载地址
 * @param destination 保存路径
 * @returns Promise<void>
 */
private downloadFile(url: string, destination: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const request = net.request(url);
    
    request.on('response', (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`下载失败: HTTP ${response.statusCode}`));
        return;
      }
      
      const fileStream = fs.createWriteStream(destination);
      
      // 设置进度监听
      let receivedBytes = 0;
      const totalBytes = parseInt(response.headers['content-length'] || '0', 10);
      
      response.on('data', (chunk) => {
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          this.emit('progress', Math.floor((receivedBytes / totalBytes) * 100));
        }
      });
      
      // 管道连接响应和文件流
      pipeline(response, fileStream, (error) => {
        if (error) {
          reject(error);
        } else {
          resolve();
        }
      });
    });
    
    request.on('error', (error) => {
      reject(error);
    });
    
    request.end();
  });
}
```

### 2. 解压机制

```typescript
/**
 * 解压插件包
 * @param packagePath 插件包路径
 * @param destPath 目标目录
 * @returns Promise<void>
 */
private async extractPackage(packagePath: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    try {
      // 使用内置的解压库
      extract(packagePath, { dir: destPath }, (err) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    } catch (error) {
      reject(error);
    }
  });
}
```

### 3. 验证机制

```typescript
/**
 * 验证插件包
 * @param packagePath 插件包路径
 * @returns Promise<boolean>
 */
private async validatePackage(packagePath: string): Promise<boolean> {
  // 简单检查是否为有效的zip文件
  try {
    const yauzl = require('yauzl');
    return new Promise((resolve, reject) => {
      yauzl.open(packagePath, { lazyEntries: true }, (err, zipfile) => {
        if (err || !zipfile) {
          resolve(false);
          return;
        }
        
        zipfile.on('entry', (entry) => {
          if (entry.fileName === 'manifest.json') {
            // 找到清单文件
            resolve(true);
            zipfile.close();
          } else {
            zipfile.readEntry();
          }
        });
        
        zipfile.on('end', () => {
          resolve(false);
        });
        
        zipfile.readEntry();
      });
    });
  } catch (error) {
    console.error('验证失败:', error);
    return false;
  }
}
```

## 安装目录结构

```
{userData}/
└── plugins/
    ├── registry.json           # 插件注册表
    ├── plugin-a/               # 插件A目录
    │   ├── manifest.json       # 插件清单
    │   ├── index.js            # 主文件
    │   └── ...                 # 其他文件
    ├── plugin-b/               # 插件B目录
    │   ├── manifest.json
    │   ├── index.js
    │   └── ...
    └── ...
```

## 插件注册表格式

`registry.json` 文件保存已安装插件的信息：

```json
{
  "plugin-a": {
    "version": "1.0.0",
    "installedAt": "2023-05-01T12:34:56.789Z",
    "enabled": true,
    "source": "https://example.com/plugins/plugin-a.buddy"
  },
  "plugin-b": {
    "version": "2.1.0",
    "installedAt": "2023-05-15T09:12:34.567Z",
    "enabled": true,
    "source": "local"
  }
}
```

## 错误处理

安装过程中可能遇到的错误及处理策略：

1. **下载失败**：重试或提供错误信息
2. **验证失败**：拒绝安装并显示具体原因
3. **解压失败**：清理临时文件并报告错误
4. **目录冲突**：提示用户是否覆盖或升级

## 卸载机制

卸载插件时，系统执行以下操作：

1. 停用并卸载插件实例
2. 删除插件目录
3. 从注册表中移除插件记录 