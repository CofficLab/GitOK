import { Logger } from '../utils/logger';

/**
 * IDE服务基类
 * 定义统一的工作空间获取接口
 */
export abstract class BaseIDEService {
    protected logger: Logger;

    constructor(serviceName: string) {
        this.logger = new Logger(serviceName);
    }

    /**
     * 获取IDE的工作空间路径
     * @returns 工作空间路径，如果获取失败则返回null
     */
    abstract getWorkspace(): Promise<string | null>;

    /**
     * 查找存储路径
     * @returns 存储文件路径
     */
    protected abstract findStoragePath(): Promise<string | null>;
}