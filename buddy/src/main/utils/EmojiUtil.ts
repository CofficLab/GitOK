/**
 * Emoji工具类 - 智能文本到表情转换工具
 * 
 * 这个工具类提供了根据输入文本智能匹配emoji表情的功能。它通过分析文本内容，
 * 结合预定义的emoji映射和相关词库，计算最佳匹配分数来选择合适的emoji。
 * 
 * @example
 * // 基本使用方法
 * import { EmojiUtil } from './utils/EmojiUtil';
 * 
 * // 根据文本获取emoji
 * const emoji1 = EmojiUtil.getEmoji('操作成功'); // 返回 '✅' 或 '🎉' 或 '👍'
 * const emoji2 = EmojiUtil.getEmoji('删除文件'); // 返回 '🗑️' 或 '❌' 或 '➖'
 * 
 * @remarks
 * - 支持多种匹配策略：完全匹配、部分匹配和相关词匹配
 * - 支持中英文关键词
 * - 包含丰富的预定义emoji分类：状态、动作、对象和情感相关
 * - 当找不到匹配时，默认返回 '📝'
 * 
 * @see
 * - emojiMappings - 预定义的emoji映射表
 * - keywordWeights - 不同匹配策略的权重配置
 */

// 预定义的emoji映射表
const emojiMappings = {
    // 状态相关
    success: ['✅', '🎉', '👍'],
    error: ['❌', '💔', '😱'],
    warning: ['⚠️', '🚨', '💡'],
    info: ['ℹ️', '📝', '💬'],
    debug: ['🔍', '🐛', '🔧'],

    // 动作相关
    create: ['✨', '🆕', '➕'],
    delete: ['🗑️', '❌', '➖'],
    update: ['🔄', '📝', '✏️'],
    search: ['🔍', '👀', '🎯'],
    download: ['⬇️', '📥', '💾'],
    upload: ['⬆️', '📤', '☁️'],
    sync: ['🔄', '♻️', '🔁'],
    lock: ['🔒', '🔐', '🔑'],
    unlock: ['🔓', '🚪', '🎊'],

    // 对象相关
    file: ['📄', '📝', '📃'],
    folder: ['📁', '📂', '🗂️'],
    code: ['💻', '👨‍💻', '🔧'],
    data: ['📊', '📈', '💾'],
    time: ['⏰', '⌚', '🕒'],
    user: ['👤', '👨', '👩'],
    group: ['👥', '🤝', '👨‍👩‍👧‍👦'],
    settings: ['⚙️', '🔧', '🛠️'],

    // 情感相关
    happy: ['😊', '😄', '🎉'],
    sad: ['😢', '😭', '💔'],
    angry: ['😠', '😡', '💢'],
    confused: ['😕', '🤔', '❓'],
    surprised: ['😲', '😮', '😱']
};

// 关键词权重配置
const keywordWeights = {
    exact: 1.0,    // 完全匹配
    partial: 0.6,  // 部分匹配
    related: 0.3   // 相关词匹配
};

export class EmojiUtil {
    /**
     * 根据输入文本智能匹配最合适的emoji
     * @param text 输入文本
     * @returns 匹配到的emoji
     */
    static getEmoji(text: string): string {
        const normalizedText = text.toLowerCase();
        let bestMatch = {
            category: '',
            score: 0
        };

        // 遍历所有emoji类别进行匹配度评分
        for (const [category] of Object.entries(emojiMappings)) {
            let score = 0;

            // 完全匹配
            if (normalizedText.includes(category)) {
                score += keywordWeights.exact;
            }

            // 部分匹配
            if (category.split('').some(char => normalizedText.includes(char))) {
                score += keywordWeights.partial;
            }

            // 相关词匹配（可以根据需要扩展更多相关词）
            const relatedWords = this.getRelatedWords(category);
            if (relatedWords.some(word => normalizedText.includes(word))) {
                score += keywordWeights.related;
            }

            // 更新最佳匹配
            if (score > bestMatch.score) {
                bestMatch = { category, score };
            }
        }

        // 如果找到匹配，随机返回该类别的一个emoji
        if (bestMatch.score > 0) {
            const matchedEmojis = emojiMappings[bestMatch.category];
            return matchedEmojis[Math.floor(Math.random() * matchedEmojis.length)];
        }

        // 默认返回一个通用的emoji
        return '📝';
    }

    /**
     * 获取类别的相关词列表
     * @param category emoji类别
     * @returns 相关词数组
     */
    private static getRelatedWords(category: string): string[] {
        const relatedWordsMap = {
            success: ['成功', 'ok', 'done', 'complete', 'pass'],
            error: ['错误', 'fail', 'failed', 'wrong', 'bad'],
            warning: ['警告', 'caution', 'notice', 'careful'],
            info: ['信息', 'message', 'note', 'inform'],
            debug: ['调试', 'test', 'check', 'trace'],
            create: ['创建', 'new', 'add', 'make'],
            delete: ['删除', 'remove', 'clear', 'clean'],
            update: ['更新', 'modify', 'change', 'edit'],
            search: ['搜索', 'find', 'query', 'look'],
            download: ['下载', 'fetch', 'get', 'receive'],
            upload: ['上传', 'push', 'send', 'put'],
            sync: ['同步', 'synchronize', 'refresh'],
            lock: ['锁定', 'secure', 'protect'],
            unlock: ['解锁', 'free', 'release'],
            file: ['文件', 'document', 'text'],
            folder: ['文件夹', 'directory', 'path'],
            code: ['代码', 'program', 'script'],
            data: ['数据', 'information', 'content'],
            time: ['时间', 'date', 'clock', 'schedule'],
            user: ['用户', 'account', 'person'],
            group: ['群组', 'team', 'members'],
            settings: ['设置', 'configuration', 'preferences'],
            happy: ['开心', 'glad', 'pleased', 'joy'],
            sad: ['悲伤', 'unhappy', 'sorry', 'upset'],
            angry: ['愤怒', 'mad', 'fury', 'rage'],
            confused: ['困惑', 'puzzled', 'unsure'],
            surprised: ['惊讶', 'amazed', 'shocked']
        };

        return relatedWordsMap[category] || [];
    }

    /**
     * 根据输入文本获取emoji并与原文本拼接
     * @param text 输入文本
     * @returns emoji + 原文本
     */
    static getEmojiWithText(text: string): string {
        const emoji = this.getEmoji(text);
        return `${emoji}${text}`;
    }
}