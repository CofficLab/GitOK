const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

try {
  // 确保目标目录存在
  const outDir = path.resolve(__dirname, '../build/Release');
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  // 编译原生模块
  execSync('node-gyp rebuild', {
    stdio: 'inherit',
    cwd: __dirname, // 确保在 native 目录下执行命令
  });

  // 复制编译后的文件到目标目录
  const buildDir = path.resolve(__dirname, 'build/Release');
  const targetFile = path.resolve(outDir, 'active-app.node');
  fs.copyFileSync(path.resolve(buildDir, 'active-app.node'), targetFile);

  // 删除源目录
  fs.rmSync(path.resolve(__dirname, 'build'), { recursive: true, force: true });

  console.log('构建成功');
} catch (error) {
  console.error('构建失败');
  process.exit(1);
}
