/**
 * AI功能管理器
 * 
 * 提供AI聊天、补全等功能
 * 使用 Vercel AI SDK 管理不同的AI供应商
 * 支持 OpenAI、Anthropic 和 DeepSeek
 */

import { logger } from './LogManager'
import { LanguageModelV1, streamText, type CoreMessage } from 'ai'
import { openai } from '@ai-sdk/openai'
import { anthropic } from '@ai-sdk/anthropic'
import { createDeepSeek } from '@ai-sdk/deepseek'

// AI模型类型
export type AIModelType = 'openai' | 'anthropic' | 'deepseek'

// AI模型配置
interface AIModelConfig {
    type: AIModelType
    modelName: string
    apiKey: string
    system?: string
    temperature?: number
    maxTokens?: number
}

// 聊天消息类型
export interface ChatMessage {
    role: 'user' | 'assistant' | 'system'
    content: string
}

// 默认的系统提示词
const DEFAULT_SYSTEM_PROMPT = '你是一个有用的AI助手。'

// 配置状态
type ConfigState = 'unconfigured' | 'selecting_provider' | 'entering_key' | 'configured'

class AIManager {
    private defaultModel: AIModelConfig = {
        type: 'openai',
        modelName: 'gpt-3.5-turbo',
        apiKey: '',  // 需要设置真实的API密钥
        system: DEFAULT_SYSTEM_PROMPT,
        temperature: 0.7,
        maxTokens: 2000
    }

    // 配置状态
    private configState: ConfigState = 'unconfigured'

    // 内存中的API密钥存储
    private apiKeys: Map<AIModelType, string> = new Map()

    // 活跃请求的AbortController集合
    private activeRequests = new Map<string, AbortController>()

    constructor() {
        logger.info('AIManager 初始化')
    }

    /**
     * 发送聊天消息
     * 返回流式响应
     */
    async sendChatMessage(messages: ChatMessage[], onChunk: (chunk: string) => void, modelConfig?: Partial<AIModelConfig>, requestId?: string): Promise<void> {
        // 创建AbortController用于取消请求
        const abortController = new AbortController()
        if (requestId) {
            // 如果之前存在同ID的请求，先取消
            this.cancelRequest(requestId)
            this.activeRequests.set(requestId, abortController)
        }

        try {
            // 合并默认配置和自定义配置
            const config = { ...this.defaultModel, ...modelConfig }

            // 如果未配置，开始配置流程
            if (this.configState === 'unconfigured') {
                onChunk(this.handleUnconfigured())
                return
            }

            // 如果正在选择供应商
            if (this.configState === 'selecting_provider') {
                onChunk(this.handleProviderSelection(messages[messages.length - 1]))
                return
            }

            // 如果正在输入密钥
            if (this.configState === 'entering_key') {
                onChunk(this.handleKeyInput(messages[messages.length - 1]))
                return
            }

            // 检查API密钥
            const apiKey = this.apiKeys.get(config.type)
            if (!apiKey) {
                this.configState = 'entering_key'
                onChunk(
                    `请输入您的 ${config.type.toUpperCase()} API密钥：\n` +
                    `(直接在聊天框中输入密钥即可，密钥将安全地保存在内存中)`
                )
                return
            }

            // 使用内存中的密钥
            config.apiKey = apiKey
            logger.info(`向 ${config.type}/${config.modelName} 发送聊天请求，消息条数: ${messages.length}`)

            // 转换消息格式为 CoreMessage
            const coreMessages: CoreMessage[] = this.preprocessMessages(messages, config.system)

            // 根据不同的模型类型调用不同的API，传入abort信号
            logger.info(`调用 ${config.type}/${config.modelName} API，参数:`, {
                temperature: config.temperature,
                maxTokens: config.maxTokens
            })

            const result = streamText({
                model: this.getModelProvider(config),
                messages: coreMessages,
                temperature: config.temperature,
                maxTokens: config.maxTokens,
                abortSignal: abortController.signal,
                onError({ error }) {
                    logger.error('AI请求错误')
                    console.error(error); // your error logging logic here
                },
            })

            for await (const chunk of result.textStream) {
                logger.info('收到chunk:', chunk)
                onChunk(chunk)
            }
        } catch (error) {
            logger.error('AI请求失败:', error)
            throw this.handleError(error)
        } finally {
            // 如果有requestId，在最后清理资源
            if (requestId && !abortController.signal.aborted) {
                this.activeRequests.delete(requestId)
            }
        }
    }

    /**
     * 取消指定ID的请求
     * @param requestId 请求ID
     * @returns 是否成功取消
     */
    cancelRequest(requestId: string): boolean {
        const controller = this.activeRequests.get(requestId)
        if (controller) {
            controller.abort()
            this.activeRequests.delete(requestId)
            logger.info(`已取消请求 ${requestId}`)
            return true
        }
        return false
    }

    /**
     * 处理未配置状态
     */
    private handleUnconfigured(): string {
        this.configState = 'selecting_provider'
        const providers = this.getAvailableModels()
        const message =
            '欢迎使用AI助手！请选择您想使用的AI供应商：\n\n' +
            Object.entries(providers)
                .map(([type, models], index) =>
                    `${index + 1}. ${type.toUpperCase()} (支持的模型: ${models.join(', ')})`)
                .join('\n') +
            '\n\n(请输入数字 1-3 选择供应商)'

        return message
    }

    /**
     * 处理供应商选择
     */
    private handleProviderSelection(message: ChatMessage): string {
        const providers = Object.keys(this.getAvailableModels())
        const choice = parseInt(message.content)

        if (isNaN(choice) || choice < 1 || choice > providers.length) {
            return '请输入有效的数字选择供应商 (1-3):\n\n' +
                providers.map((type, index) => `${index + 1}. ${type.toUpperCase()}`).join('\n')
        }

        const selectedType = providers[choice - 1] as AIModelType
        const models = this.getAvailableModels()[selectedType]

        // 更新默认配置
        this.defaultModel.type = selectedType
        this.defaultModel.modelName = models[0]  // 使用第一个模型作为默认值

        // 进入输入密钥状态
        this.configState = 'entering_key'
        return `您选择了 ${selectedType.toUpperCase()}，使用默认模型 ${models[0]}。\n` +
            `请输入您的 ${selectedType.toUpperCase()} API密钥：\n` +
            `(直接在聊天框中输入密钥即可，密钥将安全地保存在内存中)`
    }

    /**
     * 处理密钥输入
     */
    private handleKeyInput(message: ChatMessage): string {
        const apiKey = message.content.trim()

        if (apiKey.length < 20) {  // 简单的密钥长度检查
            return '请输入有效的API密钥（至少20个字符）'
        }

        // 保存密钥
        this.apiKeys.set(this.defaultModel.type, apiKey)
        this.configState = 'configured'

        return `${this.defaultModel.type.toUpperCase()} API密钥已保存！\n` +
            '现在您可以开始聊天了。\n' +
            '提示：您可以随时输入新的API密钥来更新配置。'
    }

    /**
     * 处理错误并返回友好的错误信息
     */
    private handleError(error: unknown): Error {
        logger.error('AI请求错误:', error)
        console.error(error)
        const errorMessage = error instanceof Error ? error.message : String(error)

        // 提供更友好的错误信息
        let userFriendlyMessage = errorMessage

        // 针对常见错误类型提供更易理解的错误信息
        if (errorMessage.includes('API key') || errorMessage.includes('apiKey')) {
            if (errorMessage.includes('missing') || errorMessage.includes('未设置')) {
                userFriendlyMessage = 'API密钥未设置，请先设置API密钥'
            } else {
                userFriendlyMessage = '无效的API密钥，请检查您的API密钥设置'
                // 重置配置状态，要求重新输入密钥
                this.configState = 'entering_key'
            }
        } else if (errorMessage.includes('network') || errorMessage.includes('timeout') || errorMessage.includes('ECONNREFUSED')) {
            userFriendlyMessage = '网络连接错误，请检查您的网络连接'
        } else if (errorMessage.includes('rate limit') || errorMessage.includes('quota')) {
            userFriendlyMessage = 'API请求超出限额，请稍后再试或检查您的账户额度'
        } else if (errorMessage.includes('context length') || errorMessage.includes('max_tokens')) {
            userFriendlyMessage = '对话内容过长，请尝试清空对话或减少输入长度'
        }

        return new Error(userFriendlyMessage)
    }

    /**
     * 获取模型提供者
     */
    private getModelProvider(config: AIModelConfig): LanguageModelV1 {
        switch (config.type) {
            case 'openai':
                return openai(config.modelName)
            case 'anthropic':
                return anthropic(config.modelName)
            case 'deepseek':
                const apiKey = this.apiKeys.get(config.type)
                const deepseek = createDeepSeek({
                    apiKey: apiKey,
                });
                return deepseek(config.modelName)
            default:
                throw new Error(`不支持的模型类型: ${config.type}`)
        }
    }

    /**
     * 预处理消息，确保系统提示在最前面
     */
    private preprocessMessages(messages: ChatMessage[], systemPrompt?: string): CoreMessage[] {
        const result: CoreMessage[] = []

        // 添加系统提示消息
        if (systemPrompt) {
            result.push({
                role: 'system',
                content: systemPrompt
            })
        }

        // 添加其他非系统消息
        for (const message of messages) {
            if (message.role !== 'system') {
                result.push({
                    role: message.role,
                    content: message.content
                })
            }
        }

        return result
    }

    /**
     * 设置默认模型配置
     */
    setDefaultModel(config: Partial<AIModelConfig>) {
        this.defaultModel = { ...this.defaultModel, ...config }
        logger.info(`更新默认AI模型: ${this.defaultModel.type}/${this.defaultModel.modelName}`)

        // 如果提供了新的API密钥，更新内存中的存储
        if (config.apiKey) {
            this.apiKeys.set(this.defaultModel.type, config.apiKey)
            this.configState = 'configured'
        }
    }

    /**
     * 获取默认模型配置
     */
    getDefaultModelConfig(): AIModelConfig {
        // 从内存中获取API密钥
        const apiKey = this.apiKeys.get(this.defaultModel.type) || ''
        return { ...this.defaultModel, apiKey }
    }

    /**
     * 获取支持的模型列表
     * 提供预设的模型选项
     */
    getAvailableModels(): { [key in AIModelType]: string[] } {
        return {
            openai: [
                'gpt-3.5-turbo',
                'gpt-4',
                'gpt-4-turbo'
            ],
            anthropic: [
                'claude-3-opus-20240229',
                'claude-3-sonnet-20240229',
                'claude-3-haiku-20240307'
            ],
            deepseek: [
                'deepseek-chat',
                'deepseek-coder',
                'deepseek-chat-v1.5'
            ]
        }
    }

    /**
     * 重置配置
     * 用于用户想要重新配置时调用
     */
    resetConfig() {
        this.configState = 'unconfigured'
        this.apiKeys.clear()
        this.defaultModel.apiKey = ''
    }
}

// 导出单例
export const aiManager = new AIManager()