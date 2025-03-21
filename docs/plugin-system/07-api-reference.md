# 7. API 参考

Buddy 插件系统为插件开发者提供了丰富的 API，用于与应用交互、创建用户界面和访问系统功能。

## API 命名空间

Buddy 插件 API 组织为以下命名空间：

- `buddy.app` - 应用信息和控制
- `buddy.ui` - 用户界面元素
- `buddy.fs` - 文件系统操作
- `buddy.net` - 网络访问
- `buddy.clipboard` - 剪贴板操作
- `buddy.notifications` - 通知系统
- `buddy.shell` - 命令行功能
- `buddy.store` - 数据存储

## 全局 API

### buddy.version

获取 Buddy 应用版本。

```typescript
const version = buddy.version;
console.log(`Buddy 版本: ${version}`);
```

### buddy.env

获取环境信息。

```typescript
const env = buddy.env;
console.log(`运行环境: ${env.os}, ${env.arch}`);
```

## 应用 API (buddy.app)

### buddy.app.info

获取应用信息。

```typescript
const info = buddy.app.info;
console.log(`应用名称: ${info.name}`);
console.log(`应用路径: ${info.path}`);
```

### buddy.app.restart()

重启应用。

```typescript
await buddy.app.restart();
```

## 用户界面 API (buddy.ui)

### buddy.ui.showMessage(message, [options])

显示消息对话框。

```typescript
await buddy.ui.showMessage('操作已完成', { type: 'info' });
```

### buddy.ui.showDialog(options)

显示自定义对话框。

```typescript
const result = await buddy.ui.showDialog({
  title: '确认操作',
  message: '确定要执行此操作吗？',
  buttons: ['确定', '取消'],
  defaultId: 0
});

if (result.button === 0) {
  // 用户点击了"确定"
}
```

### buddy.ui.registerView(viewOptions)

注册插件视图。

```typescript
const view = await buddy.ui.registerView({
  id: 'my-plugin.mainView',
  title: '我的视图',
  component: './components/MainView.vue'
});
```

## 文件系统 API (buddy.fs)

### buddy.fs.readFile(path, [options])

读取文件内容。

```typescript
// 需要 filesystem.read 权限
try {
  const content = await buddy.fs.readFile('/path/to/file.txt', { encoding: 'utf8' });
  console.log('文件内容:', content);
} catch (error) {
  console.error('读取文件失败:', error);
}
```

### buddy.fs.writeFile(path, data, [options])

写入文件内容。

```typescript
// 需要 filesystem.write 权限
try {
  await buddy.fs.writeFile('/path/to/file.txt', '这是文件内容', { encoding: 'utf8' });
  console.log('文件写入成功');
} catch (error) {
  console.error('文件写入失败:', error);
}
```

### buddy.fs.readdir(path)

读取目录内容。

```typescript
// 需要 filesystem.read 权限
try {
  const files = await buddy.fs.readdir('/path/to/directory');
  console.log('目录内容:', files);
} catch (error) {
  console.error('读取目录失败:', error);
}
```

## 网络 API (buddy.net)

### buddy.net.fetch(url, [options])

发送 HTTP 请求。

```typescript
// 需要 network.http 权限
try {
  const response = await buddy.net.fetch('https://api.example.com/data');
  const data = await response.json();
  console.log('响应数据:', data);
} catch (error) {
  console.error('请求失败:', error);
}
```

### buddy.net.createSocket(options)

创建 WebSocket 连接。

```typescript
// 需要 network.socket 权限
try {
  const socket = await buddy.net.createSocket({
    url: 'wss://example.com/socket'
  });
  
  socket.on('message', (data) => {
    console.log('接收到消息:', data);
  });
  
  socket.send('Hello');
} catch (error) {
  console.error('创建 Socket 失败:', error);
}
```

## 剪贴板 API (buddy.clipboard)

### buddy.clipboard.readText()

读取剪贴板文本。

```typescript
// 需要 clipboard.read 权限
try {
  const text = await buddy.clipboard.readText();
  console.log('剪贴板内容:', text);
} catch (error) {
  console.error('读取剪贴板失败:', error);
}
```

### buddy.clipboard.writeText(text)

写入文本到剪贴板。

```typescript
// 需要 clipboard.write 权限
try {
  await buddy.clipboard.writeText('复制到剪贴板的文本');
  console.log('写入剪贴板成功');
} catch (error) {
  console.error('写入剪贴板失败:', error);
}
```

## 通知 API (buddy.notifications)

### buddy.notifications.show(options)

显示系统通知。

```typescript
// 需要 notifications 权限
try {
  await buddy.notifications.show({
    title: '通知标题',
    body: '通知内容',
    icon: '/path/to/icon.png'
  });
} catch (error) {
  console.error('显示通知失败:', error);
}
```

## 命令行 API (buddy.shell)

### buddy.shell.exec(command, [options])

执行命令行命令。

```typescript
// 需要 shell.execute 权限
try {
  const result = await buddy.shell.exec('ls -la', { cwd: '/path/to/directory' });
  console.log('命令输出:', result.stdout);
} catch (error) {
  console.error('执行命令失败:', error);
}
```

## 数据存储 API (buddy.store)

### buddy.store.get(key)

获取存储的数据。

```typescript
const value = await buddy.store.get('my-setting');
console.log('设置值:', value);
```

### buddy.store.set(key, value)

存储数据。

```typescript
await buddy.store.set('my-setting', 'setting-value');
console.log('设置已保存');
```

### buddy.store.delete(key)

删除存储的数据。

```typescript
await buddy.store.delete('my-setting');
console.log('设置已删除');
```

## 事件系统

### buddy.events.on(eventName, listener)

订阅事件。

```typescript
buddy.events.on('document:changed', (document) => {
  console.log('文档已更改:', document);
});
```

### buddy.events.off(eventName, listener)

取消订阅事件。

```typescript
buddy.events.off('document:changed', listener);
```

### buddy.events.emit(eventName, data)

触发事件。

```typescript
buddy.events.emit('custom-event', { key: 'value' });
```

## API 类型定义

以下是主要 API 的 TypeScript 类型定义：

```typescript
declare namespace buddy {
  const version: string;
  const env: {
    os: string;
    arch: string;
    isProduction: boolean;
  };
  
  namespace app {
    const info: {
      name: string;
      version: string;
      path: string;
    };
    
    function restart(): Promise<void>;
  }
  
  namespace ui {
    interface MessageOptions {
      type?: 'info' | 'warning' | 'error';
      buttons?: string[];
    }
    
    interface DialogOptions {
      title: string;
      message: string;
      buttons?: string[];
      defaultId?: number;
    }
    
    interface DialogResult {
      button: number;
    }
    
    interface ViewOptions {
      id: string;
      title: string;
      component: string;
      icon?: string;
    }
    
    function showMessage(message: string, options?: MessageOptions): Promise<void>;
    function showDialog(options: DialogOptions): Promise<DialogResult>;
    function registerView(options: ViewOptions): Promise<void>;
  }
  
  namespace fs {
    interface ReadOptions {
      encoding?: string;
    }
    
    interface WriteOptions {
      encoding?: string;
      mode?: number;
    }
    
    function readFile(path: string, options?: ReadOptions): Promise<string>;
    function writeFile(path: string, data: string, options?: WriteOptions): Promise<void>;
    function readdir(path: string): Promise<string[]>;
  }
  
  // ... 其他命名空间和接口定义
}
``` 