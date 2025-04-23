/**
 * 创建视图的参数
 * @param x 视图的x坐标
 * @param y 视图的y坐标
 * @param width 视图的宽度
 * @param height 视图的高度
 * @param pagePath 视图的内容，HTML文件路径
 * @returns createViewArgs
 */
export interface createViewArgs {
    x: number,
    y: number,
    width: number,
    height: number,
    pagePath: string,
}