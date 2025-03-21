/**
 * 插件打包脚本
 * 将插件打包为.buddy格式文件
 */
const fs = require("fs-extra")
const path = require("path")
const archiver = require("archiver")

// 插件根目录
const rootDir = path.resolve(__dirname, "..")
// 输出目录
const outputDir = path.join(rootDir, "dist")
// 临时目录
const tempDir = path.join(outputDir, "temp")
// 打包文件
const outputFile = path.join(outputDir, "simple-plugin.buddy")

async function bundlePlugin() {
  try {
    // 确保输出目录存在
    await fs.ensureDir(outputDir)

    // 清理临时目录
    if (await fs.pathExists(tempDir)) {
      await fs.remove(tempDir)
    }
    await fs.ensureDir(tempDir)

    // 复制清单文件
    await fs.copy(path.join(rootDir, "manifest.json"), path.join(tempDir, "manifest.json"))

    // 复制构建后的index.js
    await fs.copy(path.join(rootDir, "dist", "index.js"), path.join(tempDir, "index.js"))

    // 创建组件目录
    await fs.ensureDir(path.join(tempDir, "components"))

    // 复制组件
    await fs.copy(path.join(rootDir, "src", "components"), path.join(tempDir, "components"))

    // 创建打包文件
    const output = fs.createWriteStream(outputFile)
    const archive = archiver("zip", {
      zlib: { level: 9 } // 最高压缩级别
    })

    // 监听错误
    output.on("close", () => {
      console.log(`插件已打包: ${outputFile} (${archive.pointer()} bytes)`)

      // 清理临时目录
      fs.removeSync(tempDir)
    })

    archive.on("error", (err) => {
      throw err
    })

    // 管道连接
    archive.pipe(output)

    // 添加临时目录中的文件到压缩包
    archive.directory(tempDir, false)

    // 完成压缩
    await archive.finalize()
  } catch (error) {
    console.error("打包失败:", error)
    process.exit(1)
  }
}

bundlePlugin()
