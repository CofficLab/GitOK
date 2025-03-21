<script setup lang="ts">
import { ref, onMounted, reactive, computed, watch } from 'vue'
import TitleBar from './components/TitleBar.vue'
import "./app.css"

// 模拟所有可用的插件动作
const allPluginActions = [
    { id: 'git-commit', title: "Git: 提交更改", description: "提交当前仓库的所有更改", icon: 'i-mdi-source-commit', plugin: 'git-plugin' },
    { id: 'git-pull', title: "Git: 拉取更新", description: "从远程仓库拉取最新代码", icon: 'i-mdi-source-pull', plugin: 'git-plugin' },
    { id: 'git-push', title: "Git: 推送更改", description: "将本地提交推送到远程仓库", icon: 'i-mdi-source-repository-push', plugin: 'git-plugin' },
    { id: 'git-branch', title: "Git: 创建分支", description: "创建新的功能分支", icon: 'i-mdi-source-branch-plus', plugin: 'git-plugin' },
    { id: 'git-merge', title: "Git: 合并分支", description: "合并指定分支到当前分支", icon: 'i-mdi-source-merge', plugin: 'git-plugin' },
    { id: 'git-checkout', title: "Git: 切换分支", description: "切换到指定的分支", icon: 'i-mdi-source-branch', plugin: 'git-plugin' },
    { id: 'npm-install', title: "NPM: 安装依赖", description: "安装项目依赖", icon: 'i-mdi-npm', plugin: 'npm-plugin' },
    { id: 'npm-start', title: "NPM: 启动项目", description: "启动开发服务器", icon: 'i-mdi-play', plugin: 'npm-plugin' },
    { id: 'npm-build', title: "NPM: 构建项目", description: "构建生产版本", icon: 'i-mdi-package', plugin: 'npm-plugin' },
    { id: 'vscode-open', title: "VSCode: 打开项目", description: "在VS Code中打开当前项目", icon: 'i-mdi-microsoft-visual-studio-code', plugin: 'vscode-plugin' }
]

// 搜索关键词
const searchKeyword = ref('')

// 搜索结果
const searchResults = computed(() => {
    if (!searchKeyword.value) {
        // 无输入时显示最常用的几个动作
        return allPluginActions.slice(0, 5)
    }

    // 关键字搜索逻辑
    const keyword = searchKeyword.value.toLowerCase()
    return allPluginActions
        .filter(action => {
            return action.title.toLowerCase().includes(keyword) ||
                action.description.toLowerCase().includes(keyword) ||
                action.plugin.toLowerCase().includes(keyword)
        })
        .sort((a, b) => {
            // 标题匹配的优先级最高
            const aInTitle = a.title.toLowerCase().includes(keyword)
            const bInTitle = b.title.toLowerCase().includes(keyword)

            if (aInTitle && !bInTitle) return -1
            if (!aInTitle && bInTitle) return 1

            // 其次是插件名称匹配
            const aInPlugin = a.plugin.toLowerCase().includes(keyword)
            const bInPlugin = b.plugin.toLowerCase().includes(keyword)

            if (aInPlugin && !bInPlugin) return -1
            if (!aInPlugin && bInPlugin) return 1

            return 0
        })
})

// 状态信息
const statusInfo = reactive({
    gitRepo: "GitOK",
    branch: "main",
    commits: 128,
    lastUpdated: "10分钟前"
})

// 搜索处理
const handleSearch = () => {
    console.log(`搜索: ${searchKeyword.value}`)
    // 点击搜索按钮时可以执行特定逻辑
}

// 处理实时输入
const handleInput = () => {
    console.log(`触发插件管理系统, 关键字: ${searchKeyword.value}`)
    // 此处可以调用真实的插件管理系统API
}

// 插件动作执行
const executePluginAction = (action) => {
    console.log(`执行插件动作: ${action.title}，来自插件: ${action.plugin}`)
    // 这里模拟执行插件动作
}

// 监听搜索关键字变化
watch(searchKeyword, (newValue) => {
    handleInput()
})

// 按下Enter键触发搜索
const handleKeyDown = (event) => {
    if (event.key === 'Enter' && searchResults.value.length > 0) {
        // 执行第一个结果的动作
        executePluginAction(searchResults.value[0])
    } else if (event.key === 'ArrowDown' && searchResults.value.length > 0) {
        // 焦点移到第一个结果（可以进一步实现完整的键盘导航）
        const firstResult = document.querySelector('.results-container li a') as HTMLElement
        firstResult?.focus()
    }
}

onMounted(() => {
    // 自动聚焦搜索框
    document.getElementById('search-input')?.focus()
})
</script>

<template>
    <div class="app-container h-screen flex flex-col justify-center items-center bg-base-100 text-base-content w-full">
        <TitleBar />

        <div class="main-container flex-1 flex flex-col overflow-hidden p-4 max-w-3xl mx-auto">
            <!-- 顶部搜索框 -->
            <div class="search-container mb-4">
                <div class="relative">
                    <input id="search-input" type="text" v-model="searchKeyword" @input="handleInput"
                        @keydown="handleKeyDown" placeholder="搜索Git命令、NPM操作或VS Code功能..."
                        class="input input-bordered w-full pl-10 py-3 text-lg" autofocus />
                    <div class="absolute inset-y-0 left-0 flex items-center pl-3">
                        <i class="i-mdi-magnify text-xl text-primary"></i>
                    </div>
                    <button class="btn btn-primary absolute right-2 top-1/2 transform -translate-y-1/2"
                        @click="handleSearch">
                        搜索
                    </button>
                </div>
            </div>

            <!-- 中间搜索结果列表 -->
            <div class="results-container flex-1 overflow-y-auto mb-4 rounded-lg border border-base-300">
                <ul class="menu bg-base-200 rounded-lg">
                    <li v-for="result in searchResults" :key="result.id" @click="executePluginAction(result)">
                        <a class="flex items-center p-3 hover:bg-base-300 focus:bg-base-300 outline-none">
                            <i :class="result.icon" class="text-2xl mr-3"></i>
                            <div class="flex-1">
                                <div class="font-medium">{{ result.title }}</div>
                                <div class="text-sm opacity-70">{{ result.description }}</div>
                            </div>
                            <span class="badge badge-sm">{{ result.plugin }}</span>
                        </a>
                    </li>
                    <li v-if="searchResults.length === 0" class="p-4 text-center text-base-content/50">
                        没有找到匹配的结果
                    </li>
                </ul>
            </div>

            <!-- 底部状态栏 -->
            <div class="status-bar bg-base-200 p-2 rounded-lg flex justify-between items-center text-sm">
                <div class="flex items-center">
                    <i class="i-mdi-source-repository mr-1"></i>
                    <span>{{ statusInfo.gitRepo }}</span>
                    <span class="mx-2">|</span>
                    <i class="i-mdi-source-branch mr-1"></i>
                    <span>{{ statusInfo.branch }}</span>
                </div>
                <div class="flex items-center">
                    <i class="i-mdi-source-commit mr-1"></i>
                    <span>{{ statusInfo.commits }} 次提交</span>
                    <span class="mx-2">|</span>
                    <i class="i-mdi-clock-outline mr-1"></i>
                    <span>更新于 {{ statusInfo.lastUpdated }}</span>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.main-container {
    max-height: calc(100vh - 32px);
    /* 减去TitleBar的高度 */
}

.results-container {
    max-height: calc(100vh - 180px);
    /* 调整以适应搜索框和状态栏 */
}
</style>
