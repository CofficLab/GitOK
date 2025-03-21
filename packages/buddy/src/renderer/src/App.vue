<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import TitleBar from './components/TitleBar.vue'
import "./app.css"

// 模拟搜索结果数据
const searchResults = reactive([
    { id: 1, title: "GitOK: 快速启动", description: "启动GitOK应用", icon: 'i-mdi-rocket-launch' },
    { id: 2, title: "Git: 提交更改", description: "提交当前仓库的所有更改", icon: 'i-mdi-source-commit' },
    { id: 3, title: "Git: 拉取更新", description: "从远程仓库拉取最新代码", icon: 'i-mdi-source-pull' },
    { id: 4, title: "Git: 创建分支", description: "创建新的功能分支", icon: 'i-mdi-source-branch-plus' },
    { id: 5, title: "Git: 合并分支", description: "合并指定分支到当前分支", icon: 'i-mdi-source-merge' }
])

// 搜索关键词
const searchKeyword = ref('')

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
    // 这里可以添加实际的搜索逻辑
}

// 处理结果项点击
const handleResultClick = (result) => {
    console.log(`选中: ${result.title}`)
    // 这里可以添加点击后的操作逻辑
}

// 按下Enter键触发搜索
const handleKeyDown = (event) => {
    if (event.key === 'Enter') {
        handleSearch()
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
                    <input id="search-input" type="text" v-model="searchKeyword" @keydown="handleKeyDown"
                        placeholder="搜索Git命令、文件或仓库..." class="input input-bordered w-full pl-10 py-3 text-lg"
                        autofocus />
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
                    <li v-for="result in searchResults" :key="result.id" @click="handleResultClick(result)">
                        <a class="flex items-center p-3 hover:bg-base-300">
                            <i :class="result.icon" class="text-2xl mr-3"></i>
                            <div>
                                <div class="font-medium">{{ result.title }}</div>
                                <div class="text-sm opacity-70">{{ result.description }}</div>
                            </div>
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
