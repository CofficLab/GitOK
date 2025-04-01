import { Client } from "@modelcontextprotocol/sdk/client/index.js"
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";

// 替换为你的MCP Server URL， 获取地址：https://juhe.cn/mcp
const MCP_SERVER_URL = "https://mcp.juhe.cn/sse?token=xxxx"

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