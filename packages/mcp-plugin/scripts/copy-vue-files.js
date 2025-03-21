import fs from "fs"
import path from "path"
import { fileURLToPath } from "url"

// 获取当前文件的目录
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// 确保目标目录存在
const componentsDir = path.resolve(__dirname, "../dist/components")
if (!fs.existsSync(componentsDir)) {
  fs.mkdirSync(componentsDir, { recursive: true })
}

// 复制Vue组件文件
const srcComponentsDir = path.resolve(__dirname, "../src/components")
const files = fs.readdirSync(srcComponentsDir)

files.forEach((file) => {
  if (file.endsWith(".vue")) {
    const srcPath = path.join(srcComponentsDir, file)
    const destPath = path.join(componentsDir, file)
    fs.copyFileSync(srcPath, destPath)
    console.log(`复制了 ${file} 到 ${destPath}`)
  }
})

console.log("Vue组件文件复制完成!")
