# TypeScript 接入聚合MCP Server

如果你的 APP 使用 js/ts 开发，那么你可以参考这篇文章使用官方的 TypeScript SDK 通过 SSE 的方式接入聚合 MCP Server。

## 一、准备

打开这个页面：<https://www.juhe.cn/mcp>，确保

- 已申请专属 SSE URL
- 已启用“全国天气预报”能力

## 二、创建最小化项目

### 创建 package.json

```json
{
  "type": "module",
  "scripts": {
    "test": "tsc && ts-node dist/run.js"
  },
  "files": [
    "dist"
  ],
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.7.0"
  },
  "devDependencies": {
    "@types/node": "^22.13.10",
    "ts-node": "^10.9.2",
    "typescript": "^5.8.2"
  }
}
```

### 创建 src/run.ts

```ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js"
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";

// 替换为你的MCP Server URL， 获取地址：https://juhe.cn/mcp
const MCP_SERVER_URL = "https://mcp.juhe.cn/sse?token=zwXQRpARDZxxxxxxx"

try {
    const mcp = new Client({ name: "test-client", version: "1.0.0" })
    const transport = new SSEClientTransport(new URL(MCP_SERVER_URL))
    await mcp.connect(transport)

    console.log("📋 获取可用工具列表...")
    const toolsResult = await mcp.listTools()
    const tools = toolsResult.tools

    console.log("✅ 已连接到服务器，可用工具如下:")
    tools.forEach((tool, index) => {
        console.log(`  ${index + 1}. ${tool.name}`)
        console.log(`     ${tool.description}`)
    })

    const tool = tools[0]
    if (!tool) {
        throw new Error(`工具列表为空，请确认已启用了“全国天气预报”能力`)
    }

    console.log(`\n🔧 正在执行工具: ${tool.name}`)

    const result = await mcp.callTool({
        name: tool.name,
        arguments: {
            city: "北京",
        }
    })

    console.log(`\n✅ 工具执行完成`, result)
    process.exit(0)
} catch (e) {
    console.error(e)
}
```

## 三、运行项目

```bash
npm install
npm run test
```

正常情况下，你应该可以看到如下输出：

```bash
📋 获取可用工具列表...
✅ 已连接到服务器，可用工具如下:
  1. get_weather
     根据城市、地区、区县名称查询当地实时天气预报情况

🔧 正在执行工具: get_weather

✅ 工具执行完成 {
  content: [
    {
      type: 'text',
      text: "{'reason': '查询成功!', 'result': {'city': '北京', 'realtime': {'temperature': '19', 'humidity': '11', 'info': '阴', 'wid': '02', 'direct': '西风', 'power': '6级', 'aqi': '31'}, 'future': [{'date': '2025-04-01', 'temperature': '8/22℃', 'weather': '晴', 'wid': {'day': '00', 'night': '00'}, 'direct': '西北风'}, {'date': '2025-04-02', 'temperature': '7/20℃', 'weather': '晴', 'wid': {'day': '00', 'night': '00'}, 'direct': '西南风'}, {'date': '2025-04-03', 'temperature': '8/20℃', 'weather': '多云', 'wid': {'day': '01', 'night': '01'}, 'direct': '南风'}, {'date': '2025-04-04', 'temperature': '7/20℃', 'weather': '多云转晴', 'wid': {'day': '01', 'night': '00'}, 'direct': '西北风'}, {'date': '2025-04-05', 'temperature': '9/21℃', 'weather': '多云', 'wid': {'day': '01', 'night': '01'}, 'direct': '西南风'}]}, 'error_code': 0}"
    }
  ],
  isError: false
}
```

不过，这个例子只是一个最小化的例子，使用了硬编码，你应该根据实际需要优化代码以在生产环境中使用。

## 四、参考

- [官方TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
